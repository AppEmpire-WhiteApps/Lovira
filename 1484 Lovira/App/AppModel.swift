import Foundation
import Observation
import SwiftData
import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case explore
    case chats
    case gallery
    case profile

    var id: String { rawValue }
}

enum AppRoute: Hashable {
    case companion(String)
    case chat(String)
    case scenarios(String)
}

struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let icon: String
}

/// Shared app state: services, navigation and SwiftData helpers.
@Observable
final class AppModel {
    let container: ModelContainer
    let profile: UserProfile
    let access: PremiumAccess
    let speech: SpeechService
    let voicePlayer = VoicePlayer()
    let lock = AppLock()
    let engine: ChatEngine
    let photoGenerator: PhotoGenerator
    let presets: [Companion]

    var selectedTab: AppTab = .explore
    var explorePath: [AppRoute] = []
    var chatsPath: [AppRoute] = []
    var galleryPath: [AppRoute] = []
    var profilePath: [AppRoute] = []
    var isCreatePresented = false
    var editingCharacter: CustomCharacter?
    var paywallRoute: PremiumRoute?
    var isMainPaywallLoaded = false
    var isScenarioPaywallLoaded = false
    var toast: ToastMessage?
    /// Chat messages whose photo or video is being generated right now.
    var activeGenerations: Set<UUID> = []

    init(container: ModelContainer, profile: UserProfile = UserProfile(), access: PremiumAccess = PremiumAccess()) {
        self.container = container
        self.profile = profile
        self.access = access
        let client = LLMAppsClient()
        engine = ChatEngine(client: client)
        speech = SpeechService(client: client)
        photoGenerator = PhotoGenerator(client: client)
        presets = PresetCatalog.all
        migrateFreeAllowances()
        Haptics.isEnabled = profile.hapticsEnabled
        if profile.appLockEnabled {
            lock.lock()
        }
        #if DEBUG
        applyDebugLaunchOptions()
        #endif
    }

    #if DEBUG
    /// Launch arguments for simulator checks, e.g. `-debugRoute chat:mia`.
    private func applyDebugLaunchOptions() {
        let defaults = UserDefaults.standard
        guard let route = defaults.string(forKey: "debugRoute") else {
            return
        }
        let parts = route.split(separator: ":").map(String.init)
        let argument = parts.count > 1 ? parts[1] : ""
        switch parts.first {
        case "tab":
            selectedTab = AppTab(rawValue: argument) ?? .explore
        case "profile":
            explorePath = [.companion(argument)]
        case "scenarios":
            explorePath = [.scenarios(argument)]
        case "chat":
            selectedTab = .chats
            chatsPath = [.chat(argument)]
        case "create":
            isCreatePresented = true
        default:
            break
        }
    }
    #endif

    var context: ModelContext {
        container.mainContext
    }

    // MARK: Companions

    func companion(id: String) -> Companion? {
        if let preset = presets.first(where: { $0.id == id }) {
            return preset
        }
        let descriptor = FetchDescriptor<CustomCharacter>(predicate: #Predicate { $0.id == id })
        return (try? context.fetch(descriptor))?.first?.companion
    }

    // MARK: Navigation

    func showPaywall(_ route: PremiumRoute = .main) {
        speech.stop()
        voicePlayer.stop()
        paywallRoute = route
    }

    @discardableResult
    func authorize(_ feature: PremiumFeature) -> Bool {
        guard access.allows(feature) else {
            showPaywall(feature == .scenarios && access.isPremium ? .scenarios : .main)
            return false
        }
        return true
    }

    func isCharacterLocked(_ id: String) -> Bool {
        guard let character = companion(id: id) else { return true }
        return !access.isCharacterAvailable(character)
    }

    @discardableResult
    func authorizeCharacter(_ id: String) -> Bool {
        guard !isCharacterLocked(id) else {
            showPaywall()
            return false
        }
        return true
    }

    func requestCreate() {
        guard authorize(.characterCreate) else { return }
        isCreatePresented = true
    }

    func requestEdit(_ companionId: String) {
        guard authorize(.characterEdit) else { return }
        let descriptor = FetchDescriptor<CustomCharacter>(predicate: #Predicate { $0.id == companionId })
        editingCharacter = (try? context.fetch(descriptor))?.first
    }

    func prepareGalleryAccess(companionId: String, preferred: PhotoSource?) {
        guard let preferred else { return }
        access.usage.registerGalleryPhoto(key: preferred.key, companionID: companionId)
    }

    func isGalleryPhotoLocked(_ photo: PhotoSource, companionId: String) -> Bool {
        guard !access.isPremium else { return false }
        let key = access.usage.galleryPhotoKey(for: companionId) ?? companion(id: companionId)?.gallery.first?.key
        return key != photo.key
    }

    func isChatPhotoLocked(_ message: ChatMessage, companionId: String) -> Bool {
        guard !access.isPremium else { return false }
        return message.subscriptionLocked || access.usage.firstChatPhotoID(for: companionId) != message.id.uuidString
    }

    /// Existing user data is kept, but deletion cannot replenish lifetime free allowances.
    private func migrateFreeAllowances() {
        let characters = (try? context.fetch(FetchDescriptor<CustomCharacter>())) ?? []
        access.usage.accountForExistingCharacters(characters.count)
        let messages = (try? context.fetch(FetchDescriptor<ChatMessage>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        for message in messages where message.role == .assistant && message.kind == .photo
            && message.status == .sent && !message.subscriptionLocked && message.photoSource != nil {
            if let id = message.conversation?.companionId {
                access.usage.finishPhoto(from: id, messageID: message.id, success: true)
            }
        }
        let media = (try? context.fetch(FetchDescriptor<CollectedMedia>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        for item in media where !item.isVideo {
            prepareGalleryAccess(companionId: item.companionId, preferred: item.photoSource)
        }
    }

    func path(for tab: AppTab) -> Binding<[AppRoute]> {
        Binding {
            switch tab {
            case .explore: self.explorePath
            case .chats: self.chatsPath
            case .gallery: self.galleryPath
            case .profile: self.profilePath
            }
        } set: { newValue in
            switch tab {
            case .explore: self.explorePath = newValue
            case .chats: self.chatsPath = newValue
            case .gallery: self.galleryPath = newValue
            case .profile: self.profilePath = newValue
            }
        }
    }

    func openProfile(_ companionId: String) {
        guard authorizeCharacter(companionId) else { return }
        path(for: selectedTab).wrappedValue.append(.companion(companionId))
    }

    func openChat(_ companionId: String) {
        guard companion(id: companionId) != nil, authorizeCharacter(companionId) else {
            return
        }
        guard AIConsentStore.shared.request(onApprove: { [weak self] in self?.openChat(companionId) }) else {
            return
        }
        Haptics.tap()
        selectedTab = .chats
        chatsPath = [.chat(companionId)]
    }

    func showToast(_ text: String, icon: String = "sparkles") {
        let message = ToastMessage(text: text, icon: icon)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            toast = message
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            if toast == message {
                withAnimation(.easeInOut) {
                    toast = nil
                }
            }
        }
    }

    func grant(_ achievement: Achievement) {
        guard let unlocked = profile.unlock(achievement) else {
            return
        }
        Haptics.success()
        let text = LocalizedText(
            "Achievement: \(unlocked.title)",
            ru: "Достижение: \(unlocked.title)"
        ).value
        showToast(text, icon: "trophy.fill")
    }

    // MARK: Conversations

    func existingConversation(for companionId: String) -> Conversation? {
        let descriptor = FetchDescriptor<Conversation>(predicate: #Predicate { $0.companionId == companionId })
        return (try? context.fetch(descriptor))?.first
    }

    /// Returns the conversation with the companion, creating it with her greeting.
    func conversation(for companion: Companion) -> Conversation {
        if let existing = existingConversation(for: companion.id) {
            return existing
        }
        let conversation = Conversation(companionId: companion.id)
        conversation.disappearAfter = profile.defaultDisappearRaw
        context.insert(conversation)
        let greeting = ChatMessage(role: .assistant, kind: .text, text: companion.greeting)
        append(greeting, to: conversation)
        try? context.save()
        return conversation
    }

    func append(_ message: ChatMessage, to conversation: Conversation) {
        if conversation.disappearAfter > 0 {
            message.expiresAt = message.createdAt.addingTimeInterval(conversation.disappearAfter)
        }
        message.conversation = conversation
        context.insert(message)
        conversation.lastMessageAt = message.createdAt
        conversation.lastMessagePreview = preview(for: message)
    }

    func preview(for message: ChatMessage) -> String {
        switch message.kind {
        case .voice:
            return LocalizedText("🎤 Voice message", ru: "🎤 Голосовое").value
        case .photo:
            return LocalizedText("📷 Photo", ru: "📷 Фото").value
        case .video:
            return LocalizedText("🎬 Video", ru: "🎬 Видео").value
        case .text, .system:
            return message.text
        }
    }

    func refreshPreview(of conversation: Conversation) {
        if let last = conversation.sortedMessages.last(where: { $0.kind != .system }) {
            conversation.lastMessagePreview = preview(for: last)
            conversation.lastMessageAt = last.createdAt
        } else {
            conversation.lastMessagePreview = ""
        }
    }

    func startScenario(_ scenario: Scenario, with companion: Companion) {
        guard authorize(.scenarios), authorizeCharacter(companion.id) else { return }
        let conversation = conversation(for: companion)
        conversation.scenarioId = scenario.id
        let marker = ChatMessage(role: .system, kind: .system, text: scenario.title.value)
        append(marker, to: conversation)
        let opening = ChatMessage(
            role: .assistant,
            kind: .text,
            text: scenario.opening.value,
            createdAt: Date().addingTimeInterval(0.01)
        )
        append(opening, to: conversation)
        try? context.save()
        grant(.firstScenario)
        openChat(companion.id)
    }

    func endScenario(in conversation: Conversation) {
        conversation.scenarioId = nil
        let marker = ChatMessage(
            role: .system,
            kind: .system,
            text: LocalizedText("Back to normal chat", ru: "Обычный чат").value
        )
        append(marker, to: conversation)
        try? context.save()
    }

    func clear(_ conversation: Conversation) {
        for message in conversation.messages {
            MediaStore.delete(message.audioFile)
            context.delete(message)
        }
        conversation.messages.removeAll()
        conversation.scenarioId = nil
        conversation.lastMessagePreview = ""
        try? context.save()
    }

    func delete(_ conversation: Conversation) {
        for message in conversation.messages {
            MediaStore.delete(message.audioFile)
        }
        context.delete(conversation)
        try? context.save()
    }

    /// Removes messages whose disappearing timer has expired.
    func purgeExpiredMessages() {
        let now = Date.now
        let descriptor = FetchDescriptor<ChatMessage>(predicate: #Predicate { message in
            message.expiresAt != nil
        })
        guard let messages = try? context.fetch(descriptor) else {
            return
        }
        var touched: [Conversation] = []
        for message in messages where (message.expiresAt ?? .distantFuture) < now {
            MediaStore.delete(message.audioFile)
            if let conversation = message.conversation {
                touched.append(conversation)
            }
            context.delete(message)
        }
        touched.forEach(refreshPreview)
        try? context.save()
    }

    // MARK: Media

    func collect(_ photo: PhotoSource, companionId: String) {
        prepareGalleryAccess(companionId: companionId, preferred: photo)
        let all = (try? context.fetch(FetchDescriptor<CollectedMedia>())) ?? []
        guard !all.contains(where: { $0.companionId == companionId && $0.photoSource == photo }) else {
            return
        }
        context.insert(CollectedMedia(companionId: companionId, photo: photo))
    }

    func collectVideo(_ resource: String, companionId: String) {
        let all = (try? context.fetch(FetchDescriptor<CollectedMedia>())) ?? []
        guard !all.contains(where: { $0.companionId == companionId && $0.videoResource == resource }) else {
            return
        }
        context.insert(CollectedMedia(companionId: companionId, videoResource: resource))
    }

    func collectVideo(file: String, thumbnail: String, companionId: String) {
        context.insert(CollectedMedia(companionId: companionId, videoFile: file, thumbnailFile: thumbnail))
    }

    // MARK: Custom characters

    func deleteCustomCharacter(id: String) {
        let descriptor = FetchDescriptor<CustomCharacter>(predicate: #Predicate { $0.id == id })
        if let character = (try? context.fetch(descriptor))?.first {
            MediaStore.delete(character.avatarFile)
            character.photoFiles.forEach(MediaStore.delete)
            context.delete(character)
        }
        if let conversation = existingConversation(for: id) {
            delete(conversation)
        }
        let media = (try? context.fetch(FetchDescriptor<CollectedMedia>())) ?? []
        media.filter { $0.companionId == id }.forEach(context.delete)
        let facts = (try? context.fetch(FetchDescriptor<MemoryFact>())) ?? []
        facts.filter { $0.companionId == id }.forEach(context.delete)
        try? context.save()
        explorePath.removeAll()
        chatsPath.removeAll()
    }

    // MARK: Privacy

    func deleteAllData() {
        speech.stop()
        voicePlayer.stop()
        try? context.delete(model: ChatMessage.self)
        try? context.delete(model: Conversation.self)
        try? context.delete(model: MemoryFact.self)
        try? context.delete(model: CollectedMedia.self)
        try? context.delete(model: CustomCharacter.self)
        try? context.save()
        MediaStore.deleteAll()
        SpeechService.clearCache()
        profile.resetAll()
        explorePath = []
        chatsPath = []
        galleryPath = []
        profilePath = []
        selectedTab = .explore
    }
}
