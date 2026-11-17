import AVFoundation
import CryptoKit
import Foundation
import Observation

/// Companion voice: LLMApps text-to-speech with the on-device synthesizer as a fallback.
@Observable
final class SpeechService: NSObject {
    private let client: LLMAppsClient
    private let synthesizer = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?
    private var currentUtterance: AVSpeechUtterance?
    private var loadTask: Task<Void, Never>?
    private var progressTask: Task<Void, Never>?
    private var spokenLength = 0
    private var consentRequestID = UUID()
    /// After a non-retryable API error (e.g. an empty balance) the cloud voice is skipped for a while.
    private var cloudPausedUntil = Date.distantPast

    private(set) var speakingID: UUID?
    /// True while the cloud audio for `speakingID` is being generated or downloaded.
    private(set) var isPreparing = false
    /// Playback progress of the current message (0...1).
    private(set) var progress: Double = 0
    /// Length of the cloud audio being played; 0 for the on-device voice.
    private(set) var duration: Double = 0

    /// The provider accepts at most 500 characters per request.
    private static let maxChunkLength = 480

    init(client: LLMAppsClient) {
        self.client = client
        super.init()
        synthesizer.delegate = self
    }

    func toggle(text: String, style: VoiceStyle, id: UUID) {
        if speakingID == id {
            stop()
        } else {
            speak(text: text, style: style, id: id)
        }
    }

    /// Speaks the text; `onDuration` receives the real audio length when the cloud voice is used.
    func speak(text: String, style: VoiceStyle, id: UUID, onDuration: ((Double) -> Void)? = nil) {
        let requestID = consentRequestID
        guard
            AIConsentStore.shared.request(onApprove: { [weak self] in
                guard let self, self.consentRequestID == requestID else { return }
                self.speak(text: text, style: style, id: id, onDuration: onDuration)
            })
        else {
            return
        }
        stop()
        let spoken = Self.speakableText(text)
        guard !spoken.isEmpty else {
            return
        }
        speakingID = id
        isPreparing = true
        loadTask = Task { [weak self] in
            guard let self else {
                return
            }
            let file = await self.cloudAudio(for: spoken, style: style)
            guard !Task.isCancelled, self.speakingID == id else {
                return
            }
            self.isPreparing = false
            if let file, self.play(file) {
                onDuration?(self.duration)
            } else {
                self.speakOnDevice(spoken, style: style)
            }
        }
    }

    func stop() {
        consentRequestID = UUID()
        loadTask?.cancel()
        loadTask = nil
        progressTask?.cancel()
        progressTask = nil
        player?.stop()
        player = nil
        currentUtterance = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        speakingID = nil
        isPreparing = false
        progress = 0
        duration = 0
    }

    /// Rough duration of a spoken message for the voice bubble.
    static func estimatedDuration(_ text: String) -> Double {
        max(2, Double(speakableText(text).count) / 14)
    }

    /// Removes roleplay *actions* and emoji so they are not read aloud.
    static func speakableText(_ text: String) -> String {
        let withoutActions = text.replacingOccurrences(of: "\\*[^*]*\\*", with: " ", options: .regularExpression)
        let scalars = withoutActions.unicodeScalars.filter { scalar in
            !(scalar.properties.isEmojiPresentation || (scalar.properties.isEmoji && scalar.value > 0x238C))
        }
        return String(String.UnicodeScalarView(scalars))
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func clearCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
    }

    // MARK: Cloud voice

    private static var cacheDirectory: URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent("Lovira/Speech", isDirectory: true)
    }

    private static func cacheURL(text: String, style: VoiceStyle) -> URL {
        let key = "\(style.cloudVoiceID)|\(style.cloudSpeed)|\(text)"
        let hash = SHA256.hash(data: Data(key.utf8)).map { String(format: "%02x", $0) }.joined()
        return cacheDirectory.appendingPathComponent("\(hash).mp3")
    }

    /// Returns a local audio file for the text, generating it through LLMApps when it is not cached.
    private func cloudAudio(for text: String, style: VoiceStyle) async -> URL? {
        let file = Self.cacheURL(text: text, style: style)
        if FileManager.default.fileExists(atPath: file.path) {
            return file
        }
        guard Date() >= cloudPausedUntil else {
            return nil
        }
        do {
            var audio = Data()
            for chunk in Self.chunks(of: text) {
                let url = try await client.textToSpeech(
                    text: chunk,
                    voiceID: style.cloudVoiceID,
                    speed: style.cloudSpeed
                )
                audio.append(try await client.download(url))
            }
            try FileManager.default.createDirectory(at: Self.cacheDirectory, withIntermediateDirectories: true)
            try audio.write(to: file, options: .atomic)
            return file
        } catch {
            #if DEBUG
            print("Cloud TTS failed, using the on-device voice: \(error)")
            #endif
            if let apiError = error as? LLMAppsError, !apiError.isRetryable {
                cloudPausedUntil = Date().addingTimeInterval(5 * 60)
            }
            return nil
        }
    }

    /// Splits long text at sentence or word boundaries; MP3 parts can be joined back to back.
    static func chunks(of text: String) -> [String] {
        var chunks: [String] = []
        var current = ""
        text.enumerateSubstrings(in: text.startIndex..., options: .bySentences) { sentence, _, _, _ in
            guard let sentence else {
                return
            }
            for piece in splitLong(sentence) {
                if current.count + piece.count > maxChunkLength, !current.isEmpty {
                    chunks.append(current.trimmingCharacters(in: .whitespaces))
                    current = ""
                }
                current += piece
            }
        }
        let tail = current.trimmingCharacters(in: .whitespaces)
        if !tail.isEmpty {
            chunks.append(tail)
        }
        return chunks
    }

    private static func splitLong(_ sentence: String) -> [String] {
        guard sentence.count > maxChunkLength else {
            return [sentence]
        }
        var pieces: [String] = []
        var current = ""
        for word in sentence.split(separator: " ") {
            if current.count + word.count + 1 > maxChunkLength, !current.isEmpty {
                pieces.append(current)
                current = ""
            }
            current += word + " "
        }
        if !current.isEmpty {
            pieces.append(current)
        }
        return pieces
    }

    private func play(_ file: URL) -> Bool {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        guard let player = try? AVAudioPlayer(contentsOf: file), player.duration > 0 else {
            try? FileManager.default.removeItem(at: file)
            return false
        }
        player.delegate = self
        guard player.play() else {
            return false
        }
        self.player = player
        duration = player.duration
        progressTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, let player = self.player else {
                    return
                }
                self.progress = min(1, player.currentTime / player.duration)
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
        return true
    }

    // MARK: On-device voice

    private func speakOnDevice(_ text: String, style: VoiceStyle) {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = Self.voice(for: style, language: Self.languageCode(for: text))
        // Pitch shifting makes system voices sound synthetic, so only the tempo varies by style.
        utterance.pitchMultiplier = 1
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * style.rateMultiplier
        utterance.preUtteranceDelay = 0.05
        spokenLength = (text as NSString).length
        currentUtterance = utterance
        synthesizer.speak(utterance)
    }

    private static func languageCode(for text: String) -> String {
        let isCyrillic = text.unicodeScalars.contains { (0x0400...0x04FF).contains($0.value) }
        return isCyrillic ? "ru" : "en"
    }

    /// Natural-sounding female voices, best first, used when several are installed.
    private static let preferredNames = [
        "Ava", "Zoe", "Allison", "Samantha", "Susan", "Nicky", "Serena", "Kate", "Karen", "Moira",
        "Milena", "Katya"
    ]

    /// Picks the best installed female voice: premium > enhanced > default; no novelty voices.
    static func voice(for style: VoiceStyle, language: String) -> AVSpeechSynthesisVoice? {
        let candidates = AVSpeechSynthesisVoice.speechVoices().filter { voice in
            let identifier = voice.identifier.lowercased()
            return voice.language.hasPrefix(language)
                && voice.gender != .male
                && !identifier.contains("eloquence")
                && !identifier.contains("speech.synthesis")
        }
        let sorted = candidates.sorted { lhs, rhs in
            if lhs.quality != rhs.quality {
                return lhs.quality.rawValue > rhs.quality.rawValue
            }
            return rank(lhs) < rank(rhs)
        }
        guard let best = sorted.first else {
            return AVSpeechSynthesisVoice(language: language == "ru" ? "ru-RU" : "en-US")
        }
        let sameQuality = sorted.filter { $0.quality == best.quality }
        return sameQuality[style.voicePreferenceOffset % sameQuality.count]
    }

    private static func rank(_ voice: AVSpeechSynthesisVoice) -> Int {
        preferredNames.firstIndex { voice.name.hasPrefix($0) } ?? preferredNames.count
    }
}

extension SpeechService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let finished = ObjectIdentifier(player)
        Task { @MainActor in
            if let current = self.player, ObjectIdentifier(current) == finished {
                self.stop()
            }
        }
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        let spokenEnd = characterRange.location + characterRange.length
        let spoken = ObjectIdentifier(utterance)
        Task { @MainActor in
            self.updateProgress(spokenEnd: spokenEnd, utterance: spoken)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let finished = ObjectIdentifier(utterance)
        Task { @MainActor in
            self.finishSpeaking(utterance: finished)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let cancelled = ObjectIdentifier(utterance)
        Task { @MainActor in
            self.finishSpeaking(utterance: cancelled)
        }
    }

    private func isCurrent(_ utterance: ObjectIdentifier) -> Bool {
        currentUtterance.map(ObjectIdentifier.init) == utterance
    }

    private func updateProgress(spokenEnd: Int, utterance: ObjectIdentifier) {
        guard isCurrent(utterance), spokenLength > 0 else {
            return
        }
        progress = min(1, Double(spokenEnd) / Double(spokenLength))
    }

    private func finishSpeaking(utterance: ObjectIdentifier) {
        if isCurrent(utterance) {
            stop()
        }
    }
}
