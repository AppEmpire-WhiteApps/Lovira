import AVFoundation
import Foundation
import Observation

/// Records voice messages (AAC m4a, up to 60 s) and plays them back.
@Observable
final class AudioRecorder {
    static let maxDuration: TimeInterval = 60

    private var recorder: AVAudioRecorder?
    private var meterTask: Task<Void, Never>?
    private(set) var isRecording = false
    private(set) var elapsed: TimeInterval = 0
    private(set) var levels: [Float] = []

    func requestPermission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        default:
            return await AVAudioApplication.requestRecordPermission()
        }
    }

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 22_050,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.record(forDuration: Self.maxDuration)
        self.recorder = recorder
        isRecording = true
        elapsed = 0
        levels = []
        startMetering()
    }

    /// Stops recording and returns the file with its duration (nil if too short).
    func stop() -> (url: URL, duration: TimeInterval, levels: [Float])? {
        guard let recorder else {
            return nil
        }
        let duration = recorder.currentTime > 0 ? recorder.currentTime : elapsed
        recorder.stop()
        finish()
        guard duration >= 0.7 else {
            try? FileManager.default.removeItem(at: recorder.url)
            return nil
        }
        return (recorder.url, duration, levels)
    }

    func cancel() {
        guard let recorder else {
            return
        }
        recorder.stop()
        try? FileManager.default.removeItem(at: recorder.url)
        finish()
    }

    private func finish() {
        meterTask?.cancel()
        meterTask = nil
        recorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startMetering() {
        meterTask?.cancel()
        meterTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard let self, let recorder = self.recorder else {
                    return
                }
                recorder.updateMeters()
                let power = recorder.averagePower(forChannel: 0)
                let level = max(0.05, min(1, (power + 50) / 50))
                self.levels.append(level)
                self.elapsed = recorder.currentTime
                if !recorder.isRecording && self.elapsed >= Self.maxDuration - 0.2 {
                    return
                }
            }
        }
    }
}

/// Plays recorded voice messages and publishes playback progress.
@Observable
final class VoicePlayer: NSObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var progressTask: Task<Void, Never>?
    private(set) var playingID: UUID?
    /// Playback progress of the current file (0...1).
    private(set) var progress: Double = 0

    func toggle(url: URL, id: UUID) {
        if playingID == id {
            stop()
            return
        }
        stop()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        guard let player = try? AVAudioPlayer(contentsOf: url) else {
            return
        }
        player.delegate = self
        player.play()
        self.player = player
        playingID = id
        startProgressUpdates()
    }

    func stop() {
        progressTask?.cancel()
        progressTask = nil
        player?.stop()
        player = nil
        playingID = nil
        progress = 0
    }

    private func startProgressUpdates() {
        progressTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, let player = self.player, player.duration > 0 else {
                    return
                }
                self.progress = min(1, player.currentTime / player.duration)
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.stop()
        }
    }
}
