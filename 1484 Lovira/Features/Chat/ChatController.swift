import Foundation
import Observation
import SwiftData

/// Chat logic for one conversation: sending, AI replies, photos, voice and memory.
@Observable
final class ChatController {
    private let initialCompanion: Companion
    let conversation: Conversation
    private let model: AppModel

    var draft = ""
    private(set) var isTyping = false
    var isVisible = false

    var companion: Companion {
        model.companion(id: initialCompanion.id) ?? initialCompanion
    }

    init(companion: Companion, model: AppModel) {
        self.initialCompanion = companion
        self.model = model
        self.conversation = model.conversation(for: companion)
    }

    private var context: ModelContext {
        model.context
    }

    var messages: [ChatMessage] {
        conversation.sortedMessages
    }

    var scenario: Scenario? {
        model.access.hasScenarioAccess ? Scenario.find(conversation.scenarioId) : nil
    }

    var intimacyLevel: Int {
        min(5, conversation.userMessageCount / 15 + 1)
    }

    // MARK: Sending

    func sendDraft() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return
        }
        if sendText(text) { draft = "" }
    }

    @discardableResult
    func sendText(_ text: String, wantsVoice: Bool = false) -> Bool {
        let intent = requestedMedia(for: text, voice: wantsVoice)
        let wantsVoice = intent.voice
        let wantsPhoto = intent.photo
        let message = ChatMessage(role: .user, kind: .text, text: text)
        guard beginRequest(message, wantsVoice: wantsVoice, wantsPhoto: wantsPhoto) else { return false }
        registerUserMessage()
        model.append(message, to: conversation)
        save()
        Task {
            await respond(to: message, wantsPhoto: wantsPhoto, wantsVoice: wantsVoice)
        }
        return true
    }

    func requestPhoto() {
        let text = LocalizedText("Send me a photo of you 📸", ru: "Пришли мне своё фото 📸").value
        sendText(text)
    }

    func requestVoice() {
        guard model.profile.autoVoiceReplies else {
            model.showToast(
                LocalizedText("Turn on Voice replies in Settings", ru: "Включи голосовые ответы в настройках").value,
                icon: "waveform"
            )
            return
        }
        sendText(LocalizedText("Send me a voice message 🎙️", ru: "Запиши мне голосовое 🎙️").value, wantsVoice: true)
    }

    /// Voices a reply: a voice player with a progress bar appears under the text and starts playing.
    func listen(to message: ChatMessage) {
        guard model.authorize(.voice) else { return }
        model.voicePlayer.stop()
        if model.speech.speakingID == message.id {
            model.speech.stop()
            return
        }
        if message.duration == 0 {
            message.duration = SpeechService.estimatedDuration(message.text)
            save()
        }
        speak(message)
    }

    private func speak(_ message: ChatMessage) {
        guard model.access.isPremium else { return }
        model.speech.speak(text: message.text, style: companion.voice, id: message.id) { [weak self] duration in
            message.duration = duration
            self?.save()
        }
    }

    func sendPhoto(_ data: Data) {
        let message = ChatMessage(role: .user, kind: .photo, text: "")
        guard beginRequest(message) else { return }
        guard let jpeg = ImageLoader.jpegData(from: data, maxPixelSize: 1024),
            let file = try? MediaStore.save(jpeg, fileExtension: "jpg")
        else {
            model.access.usage.finishMessage(message.id, success: false)
            model.showToast(
                LocalizedText("Couldn't read the photo", ru: "Не удалось открыть фото").value,
                icon: "exclamationmark.triangle.fill")
            return
        }
        registerUserMessage()
        message.mediaFile = file
        model.append(message, to: conversation)
        save()
        Task {
            await respond(to: message, wantsPhoto: false, imageJPEG: jpeg)
        }
    }

    func sendVoice(url: URL, duration: TimeInterval) {
        let message = ChatMessage(role: .user, kind: .voice, text: "", status: .sending)
        guard beginRequest(message) else { return }
        guard let file = try? MediaStore.importFile(at: url) else {
            model.access.usage.finishMessage(message.id, success: false)
            return
        }
        registerUserMessage()
        message.audioFile = file
        message.duration = duration
        model.append(message, to: conversation)
        save()
        Task {
            await transcribeAndRespond(message)
        }
    }

    private func transcribeAndRespond(_ message: ChatMessage) async {
        guard let file = message.audioFile else {
            return
        }
        isTyping = true
        do {
            let transcript = try await model.engine.transcribe(audioURL: MediaStore.url(for: file))
            message.transcript = transcript
            message.text = transcript
            message.status = .sent
            save()
            let intent = requestedMedia(for: transcript)
            await respond(to: message, wantsPhoto: intent.photo, wantsVoice: intent.voice)
        } catch {
            model.access.usage.finishMessage(message.id, success: false)
            isTyping = false
            message.status = .failed
            save()
            showError(error)
        }
    }

    /// Retries a failed user message or a failed photo.
    func retry(_ message: ChatMessage) {
        // Video generation is retired, including retries of persisted unfinished messages.
        guard message.kind != .video else { return }
        guard AIConsentStore.shared.request() else { return }
        if message.role == .assistant, message.kind == .photo {
            Task {
                await generatePhoto(into: message)
            }
            return
        }
        if message.kind == .voice, message.transcript == nil {
            guard beginRequest(message) else { return }
            message.status = .sending
            Task {
                await transcribeAndRespond(message)
            }
            return
        }
        let intent = requestedMedia(for: message.text)
        let wantsVoice = intent.voice
        let wantsPhoto = intent.photo
        guard beginRequest(message, wantsVoice: wantsVoice, wantsPhoto: wantsPhoto) else { return }
        message.status = .sent
        save()
        Task {
            await respond(to: message, wantsPhoto: wantsPhoto, wantsVoice: wantsVoice)
        }
    }

    func regenerate(_ message: ChatMessage) {
        guard message.role == .assistant, message.id == messages.last?.id else {
            return
        }
        guard let user = messages.last(where: { $0.role == .user }), beginRequest(user) else { return }
        delete(message)
        Task {
            await respond(to: user, wantsPhoto: false)
        }
    }

    /// Guards every entry point, including retries, before an API call or an outgoing bubble is created.
    func beginRequest(_ message: ChatMessage, wantsVoice: Bool = false, wantsPhoto: Bool = false) -> Bool {
        guard AIConsentStore.shared.request() else { return false }
        guard model.authorizeCharacter(companion.id) else { return false }
        if (wantsVoice || message.kind == .voice), !model.authorize(.voice) { return false }
        guard
            model.access.usage.reserveMessage(
                message.id, premium: model.access.isPremium,
                alreadyCharged: message.freeMessageCharged)
        else {
            model.showPaywall()
            return false
        }
        if wantsPhoto,
            !model.access.usage.reservePhoto(
                from: companion.id, premium: model.access.isPremium, reservationID: message.id)
        {
            model.access.usage.finishMessage(message.id, success: false)
            model.showPaywall()
            return false
        }
        return true
    }

    private func requestedMedia(for text: String, voice: Bool = false) -> (voice: Bool, photo: Bool) {
        let voice = model.profile.autoVoiceReplies && (voice || PromptBuilder.isVoiceRequest(text))
        let photo = !voice && PromptBuilder.isPhotoRequest(text)
        return (voice, photo)
    }

    func delete(_ message: ChatMessage) {
        model.speech.stop()
        MediaStore.delete(message.audioFile)
        if message.role == .user {
            MediaStore.delete(message.mediaFile)
        }
        conversation.messages.removeAll { $0.id == message.id }
        context.delete(message)
        model.refreshPreview(of: conversation)
        save()
    }

    func setDisappear(_ option: DisappearOption) {
        conversation.disappearAfter = option.rawValue
        let notice =
            option == .off
            ? LocalizedText("Disappearing messages turned off", ru: "Исчезающие сообщения выключены").value
            : LocalizedText("Messages disappear after \(option.title)", ru: "Сообщения исчезают через \(option.title)")
                .value
        model.append(ChatMessage(role: .system, kind: .system, text: notice), to: conversation)
        save()
    }

    func markRead() {
        if conversation.unreadCount != 0 {
            conversation.unreadCount = 0
            save()
        }
    }

    // MARK: Stats

    private func registerUserMessage() {
        model.profile.totalMessages += 1
        conversation.userMessageCount += 1
        model.grant(.firstMessage)
        if model.profile.totalMessages >= 100 {
            model.grant(.hundredMessages)
        }
    }

    // MARK: AI reply

    private var canReplyWithVoice: Bool {
        model.profile.autoVoiceReplies && model.access.isPremium
    }

    private func respond(
        to userMessage: ChatMessage,
        wantsPhoto: Bool,
        wantsVoice: Bool = false,
        imageJPEG: Data? = nil
    ) async {
        defer {
            if wantsPhoto {
                model.access.usage.cancelPhotoReservation(from: companion.id, reservationID: userMessage.id)
            }
        }
        isTyping = true
        let lastUserText = messages.last(where: { $0.role == .user && !$0.text.isEmpty })?.text ?? ""
        let recentUserTexts = messages.filter { $0.role == .user && !$0.text.isEmpty }.suffix(6).map(\.text)
        let voiceForPrompt = wantsVoice && canReplyWithVoice
        let system = PromptBuilder.systemPrompt(
            companion: companion,
            userName: model.profile.displayName,
            facts: memoryFacts().map(\.text),
            scenario: scenario,
            replyLanguage: PromptBuilder.languageName(for: recentUserTexts),
            voiceMessage: voiceForPrompt,
            photoMessage: wantsPhoto && !voiceForPrompt
        )
        var history = buildHistory()
        if let imageJPEG, !history.isEmpty {
            history.removeLast()
            let caption = LocalizedText(
                "[I sent you a photo. React to it.]", ru: "[Я отправил тебе фото. Отреагируй на него.]"
            ).value
            history.append(ChatEngine.imageMessage(text: caption, jpeg: imageJPEG))
        }

        do {
            if !model.access.isPremium {
                try await Task.sleep(nanoseconds: 3_000_000_000)
            }
            let reply = try await model.engine.reply(
                system: system,
                history: history,
                maxTokens: 600
            )
            model.access.usage.finishMessage(userMessage.id, success: true)
            userMessage.freeMessageCharged = true
            save()
            let voiceReply = voiceForPrompt && canReplyWithVoice
            await deliver(reply, asVoice: voiceReply)

            if !wantsVoice, shouldSendPhoto(reply: reply, wantsPhoto: wantsPhoto) {
                await deliverPhoto(
                    prompt: reply.photoPrompt, context: lastUserText,
                    reservationID: wantsPhoto ? userMessage.id : nil)
            }
            isTyping = false
            updateMemoryIfNeeded()
        } catch {
            model.access.usage.finishMessage(userMessage.id, success: false)
            isTyping = false
            userMessage.status = .failed
            save()
            showError(error)
        }
    }

    private func deliver(_ reply: CompanionReply, asVoice: Bool) async {
        let parts = asVoice ? [reply.text] : Self.splitIntoBubbles(reply.text)
        for (index, part) in parts.enumerated() {
            if index > 0 {
                isTyping = true
                try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 0.6...1.2) * 1_000_000_000))
            }
            let kind: MessageKind = asVoice ? .voice : .text
            let message = ChatMessage(role: .assistant, kind: kind, text: part)
            if kind == .voice {
                message.duration = SpeechService.estimatedDuration(part)
            }
            appendIncoming(message)
            if kind == .voice {
                speak(message)
            }
        }
        isTyping = false
    }

    private func appendIncoming(_ message: ChatMessage) {
        model.append(message, to: conversation)
        if !isVisible {
            conversation.unreadCount += 1
        }
        save()
    }

    /// Splits a long reply into up to three chat bubbles.
    static func splitIntoBubbles(_ text: String) -> [String] {
        let paragraphs =
            text
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard paragraphs.count > 1 else {
            return [text]
        }
        if paragraphs.count <= 3 {
            return paragraphs
        }
        return [paragraphs[0], paragraphs[1], paragraphs[2...].joined(separator: "\n")]
    }

    private func buildHistory() -> [[String: Any]] {
        let relevant = messages.filter { message in
            message.kind != .system && message.status != .generating && !message.subscriptionLocked
                && !(message.kind == .video && message.status != .sent)
                && !(message.role == .user && message.status == .failed && message.id != messages.last?.id)
        }
        return relevant.suffix(30).compactMap { message -> [String: Any]? in
            let role = message.role == .user ? "user" : "assistant"
            let content: String
            switch message.kind {
            case .photo:
                if message.role == .user {
                    content = "[The user sent you a photo]"
                } else {
                    content = "[You sent the user a photo of yourself: \(message.photoPrompt ?? "a selfie")]"
                }
            case .video:
                content = "[You sent the user a short video of yourself: \(message.photoPrompt ?? "a selfie video")]"
            case .voice:
                content = message.transcript ?? message.text
            case .text, .system:
                content = message.text
            }
            guard !content.isEmpty else {
                return nil
            }
            return ["role": role, "content": content]
        }
    }

    // MARK: Photos

    private func shouldSendPhoto(reply: CompanionReply, wantsPhoto: Bool) -> Bool {
        if wantsPhoto {
            return true
        }
        guard reply.sendPhoto else {
            return false
        }
        let recent = messages.suffix(14)
        let hasRecentPhoto = recent.contains { $0.role == .assistant && $0.kind == .photo }
        return !hasRecentPhoto && Double.random(in: 0...1) < 0.35
    }

    /// Adds a photo bubble and generates a new photo of the companion for it.
    private func deliverPhoto(prompt: String, context userText: String, reservationID: UUID?) async {
        let message = ChatMessage(role: .assistant, kind: .photo, text: "", status: .generating)
        message.photoPrompt = prompt.isEmpty ? sceneIdea(query: userText) : prompt
        appendIncoming(message)
        isTyping = false
        await generatePhoto(into: message, reservationID: reservationID)
    }

    private var generationSeed: Int {
        companion.seed ?? Int.random(in: 1...999_999_999)
    }

    private func generatePhoto(into message: ChatMessage, reservationID: UUID? = nil) async {
        guard AIConsentStore.shared.request() else { return }
        guard !model.activeGenerations.contains(message.id) else { return }
        guard model.authorizeCharacter(companion.id) else { return }
        let reservationID = reservationID ?? message.id
        guard
            model.access.usage.reservePhoto(
                from: companion.id, premium: model.access.isPremium, reservationID: reservationID)
        else {
            message.subscriptionLocked = true
            message.status = .sent
            save()
            return
        }
        var success = false
        defer {
            model.access.usage.finishPhoto(
                from: companion.id, messageID: message.id,
                success: success, reservationID: reservationID)
        }
        message.status = .generating
        save()
        model.activeGenerations.insert(message.id)
        defer { model.activeGenerations.remove(message.id) }
        let scene = message.photoPrompt ?? sceneIdea(query: "")
        do {
            let files = try await model.photoGenerator.generate(
                appearance: companion.appearancePrompt,
                scene: scene,
                seed: generationSeed
            )
            guard let file = files.first else {
                throw LLMAppsError.emptyResponse
            }
            message.mediaFile = file
            message.subscriptionLocked = false
            success = true
            finishPhoto(message, photo: .file(file))
        } catch {
            message.status = .failed
            save()
            showError(error)
        }
    }

    /// Ends interrupted placeholders. Only photos can be retried; legacy videos remain unavailable.
    func recoverInterruptedMedia() {
        var changed = false
        for message in messages {
            let interruptedVideo =
                message.kind == .video
                && (message.status == .generating || message.status == .sending)
            let interruptedGeneration =
                message.status == .generating
                && !model.activeGenerations.contains(message.id)
            if interruptedVideo || interruptedGeneration {
                message.status = .failed
                changed = true
            }
        }
        if changed {
            save()
        }
    }

    private func finishPhoto(_ message: ChatMessage, photo: PhotoSource) {
        message.status = .sent
        model.collect(photo, companionId: companion.id)
        model.refreshPreview(of: conversation)
        save()
        model.grant(.firstPhoto)
    }

    /// Picks a scene for a generated photo when the chat model gave none: keyword match first,
    /// preferring scenes that were not used recently.
    private func sceneIdea(query: String) -> String {
        let personal = companion.chatPhotoPool.map { (keywords: $0.keywords, caption: $0.caption) }
        let ideas = personal + PhotoGenerator.defaultScenes
        let lowered = query.lowercased()
        let used = Set(messages.suffix(30).compactMap(\.photoPrompt))
        let scored = ideas.map { idea in
            (caption: idea.caption, score: idea.keywords.filter { lowered.contains($0) }.count)
        }
        let fresh = scored.filter { !used.contains($0.caption) }
        let candidates = fresh.isEmpty ? scored : fresh
        let best = candidates.map(\.score).max() ?? 0
        return candidates.filter { $0.score == best }.randomElement()?.caption ?? PhotoGenerator.portraitScene
    }

    // MARK: Memory

    private func memoryFacts() -> [MemoryFact] {
        let id = companion.id
        let descriptor = FetchDescriptor<MemoryFact>(
            predicate: #Predicate { $0.companionId == id },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private func updateMemoryIfNeeded() {
        guard AIConsentStore.shared.hasGranted else { return }
        guard conversation.userMessageCount - conversation.memoryCheckpoint >= 10 else {
            return
        }
        conversation.memoryCheckpoint = conversation.userMessageCount
        let transcript =
            messages
            .filter { $0.kind != .system && !$0.text.isEmpty }
            .suffix(24)
            .map { "\($0.role == .user ? "User" : companion.name): \($0.text)" }
            .joined(separator: "\n")
        let existing = memoryFacts()
        let companionId = companion.id
        Task {
            guard let facts = try? await model.engine.extractFacts(transcript: transcript, known: existing.map(\.text))
            else {
                return
            }
            var known = Set(existing.map { $0.text.lowercased() })
            var count = existing.count
            for fact in facts where !known.contains(fact.lowercased()) && count < 50 {
                context.insert(MemoryFact(companionId: companionId, text: fact))
                known.insert(fact.lowercased())
                count += 1
            }
            save()
        }
    }

    // MARK: Helpers

    private func showError(_ error: Error) {
        Haptics.warning()
        let text =
            (error as? LocalizedError)?.errorDescription
            ?? LocalizedText("Something went wrong", ru: "Что-то пошло не так").value
        model.showToast(text, icon: "exclamationmark.triangle.fill")
    }

    private func save() {
        try? context.save()
    }
}
