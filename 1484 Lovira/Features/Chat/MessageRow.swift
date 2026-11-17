import SwiftUI

struct BubbleShape: Shape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let large: CGFloat = 20
        let small: CGFloat = 6
        let radii = RectangleCornerRadii(
            topLeading: large,
            bottomLeading: isUser ? large : small,
            bottomTrailing: isUser ? small : large,
            topTrailing: large
        )
        return UnevenRoundedRectangle(cornerRadii: radii, style: .continuous).path(in: rect)
    }
}

struct MessageRow: View {
    let message: ChatMessage
    let companion: Companion
    let isLastAssistant: Bool
    let controller: ChatController
    let onOpenPhoto: (PhotoSource) -> Void
    let onOpenVideo: (URL) -> Void

    @Environment(AppModel.self) private var model

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        if message.kind == .system {
            systemRow
        } else {
            HStack(alignment: .bottom, spacing: 8) {
                if isUser {
                    Spacer(minLength: 48)
                    if message.status == .failed && message.kind != .video {
                        retryButton
                    }
                } else {
                    AvatarView(source: companion.avatar, size: 28)
                }
                VStack(alignment: isUser ? .trailing : .leading, spacing: 3) {
                    content
                        .contextMenu {
                            contextActions
                        }
                    footer
                }
                if !isUser {
                    if message.kind == .photo && message.status == .failed {
                        retryButton
                    }
                    Spacer(minLength: 48)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch message.kind {
        case .text, .system:
            if !isUser && message.duration > 0 {
                // A listened-to reply keeps its text and gets a voice player underneath.
                VStack(alignment: .leading, spacing: 6) {
                    textBubble
                    VoiceBubble(message: message, companion: companion, controller: controller, showsTextToggle: false)
                }
            } else {
                textBubble
            }
        case .voice:
            VoiceBubble(message: message, companion: companion, controller: controller)
        case .photo:
            photoBubble
        case .video:
            videoBubble
        }
    }

    private var textBubble: some View {
        Text(Self.styled(message.text))
            .font(.appBody)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                if isUser {
                    BubbleShape(isUser: true).fill(Theme.ctaGradient)
                } else {
                    BubbleShape(isUser: false).fill(Theme.surfaceHigh)
                }
            }
            .textSelection(.enabled)
    }

    /// Renders roleplay *actions* in italics.
    static func styled(_ text: String) -> AttributedString {
        var result = AttributedString()
        let parts = text.components(separatedBy: "*")
        for (index, part) in parts.enumerated() where !part.isEmpty {
            var piece = AttributedString(part)
            if index % 2 == 1 && parts.count > 2 {
                piece.font = .poppins(15, .regular).italic()
                piece.foregroundColor = Color.white.opacity(0.75)
            }
            result.append(piece)
        }
        return result
    }

    private var photoBubble: some View {
        let source = message.photoSource
        let locked = message.status == .sent && model.isChatPhotoLocked(message, companionId: companion.id) && !isUser
        return ZStack {
            if message.status == .generating {
                ZStack {
                    Theme.surfaceHigh
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.ctaGradient)
                        Text(
                            LocalizedText("\(companion.name) is taking a photo…", ru: "\(companion.name) делает фото…")
                                .value
                        )
                        .font(.appCaption)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                    }
                }
                .shimmering()
            } else if message.status == .failed && source == nil {
                ZStack {
                    Theme.surfaceHigh
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.error)
                        Text("Photo didn't send")
                            .font(.appCaption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            } else {
                PhotoView(source: source ?? (locked ? companion.cover : nil), maxPixelSize: 800)
            }
        }
        .frame(width: 220, height: 293)
        .premiumLocked(locked) { model.showPaywall() }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            guard !locked else {
                model.showPaywall()
                return
            }
            if message.subscriptionLocked && model.access.isPremium {
                controller.retry(message)
                return
            }
            guard message.status == .sent, let source else {
                return
            }
            onOpenPhoto(source)
        }
    }

    private var videoBubble: some View {
        ZStack {
            if message.status != .sent {
                ZStack {
                    Theme.surfaceHigh
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.error)
                        Text(LocalizedText("Video unavailable", ru: "Видео недоступно").value)
                            .font(.appCaption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            } else {
                // Older bundled videos have no thumbnail of their own.
                PhotoView(source: message.videoFile == nil ? companion.cover : message.photoSource, maxPixelSize: 800)
                Color.black.opacity(0.25)
                Image(systemName: "play.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .frame(width: 220, height: 293)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            guard message.status == .sent else {
                return
            }
            if let file = message.videoFile {
                onOpenVideo(MediaStore.url(for: file))
            } else if let resource = message.mediaAsset,
                let url = Bundle.main.url(forResource: resource, withExtension: "mp4")
            {
                onOpenVideo(url)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 4) {
            if message.expiresAt != nil {
                Image(systemName: "timer")
            }
            Text(message.createdAt, format: .dateTime.hour().minute())
            if isUser {
                switch message.status {
                case .sending:
                    Image(systemName: "clock")
                case .failed:
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(Theme.error)
                default:
                    Image(systemName: "checkmark")
                }
            }
        }
        .font(.poppins(10))
        .foregroundStyle(Theme.textTertiary)
        .padding(.horizontal, 4)
    }

    private var retryButton: some View {
        Button {
            controller.retry(message)
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Theme.error, in: Circle())
        }
        .padding(.bottom, 18)
        .accessibilityLabel(Text("Retry"))
    }

    @ViewBuilder
    private var contextActions: some View {
        if !message.text.isEmpty {
            Button {
                UIPasteboard.general.string = message.text
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
        if !isUser && message.kind == .text {
            Button {
                controller.listen(to: message)
            } label: {
                Label("Listen", systemImage: "speaker.wave.2")
            }
        }
        if isLastAssistant && (message.kind == .text || message.kind == .voice) {
            Button {
                controller.regenerate(message)
            } label: {
                Label("Regenerate", systemImage: "arrow.triangle.2.circlepath")
            }
        }
        Button(role: .destructive) {
            controller.delete(message)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    private var systemRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .foregroundStyle(Theme.pink)
            Text(verbatim: message.text)
        }
        .font(.appCaption)
        .foregroundStyle(Theme.textSecondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Theme.surface, in: Capsule())
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

private struct VoiceBubble: View {
    let message: ChatMessage
    let companion: Companion
    let controller: ChatController
    var showsTextToggle = true

    @Environment(AppModel.self) private var model
    @State private var showsTranscript = false

    private var isUser: Bool {
        message.role == .user
    }

    private var isPlaying: Bool {
        isUser ? model.voicePlayer.playingID == message.id : model.speech.speakingID == message.id
    }

    private var progress: Double {
        guard isPlaying else {
            return 0
        }
        return isUser ? model.voicePlayer.progress : model.speech.progress
    }

    private var isPreparing: Bool {
        !isUser && isPlaying && model.speech.isPreparing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Button(action: play) {
                    ZStack {
                        if isPreparing {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    .foregroundStyle(isUser ? Theme.pinkDark : .white)
                    .frame(width: 36, height: 36)
                    .background(isUser ? AnyShapeStyle(Color.white) : AnyShapeStyle(Theme.ctaGradient), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(isPlaying ? "Pause" : "Play"))

                Waveform(seed: message.id.hashValue, progress: progress, isActive: isPlaying)
                    .frame(width: 120, height: 28)

                Text(Self.format(isPlaying ? message.duration * progress : message.duration))
                    .font(.poppins(12, .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .monospacedDigit()
            }
            if message.status == .sending {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(.white)
                    Text("Transcribing…")
                }
                .font(.appCaption)
                .foregroundStyle(.white.opacity(0.8))
            } else if showsTextToggle && !message.text.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showsTranscript.toggle()
                    }
                } label: {
                    if showsTranscript {
                        Text(verbatim: message.text)
                            .font(.appSubheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("Show text")
                            .font(.appCaptionBold)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: 280, alignment: .leading)
        .background {
            if isUser {
                BubbleShape(isUser: true).fill(Theme.ctaGradient)
            } else {
                BubbleShape(isUser: false).fill(Theme.surfaceHigh)
            }
        }
        .premiumLocked(!model.access.isPremium) { model.showPaywall() }
    }

    private func play() {
        guard model.authorize(.voice) else { return }
        if isUser {
            guard let file = message.audioFile else {
                return
            }
            model.speech.stop()
            model.voicePlayer.toggle(url: MediaStore.url(for: file), id: message.id)
        } else {
            controller.listen(to: message)
        }
    }

    static func format(_ duration: Double) -> String {
        let seconds = Int(duration.rounded())
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

struct Waveform: View {
    let seed: Int
    /// Played part of the message (0...1); bars up to this point are highlighted.
    var progress: Double = 0
    var isActive = false

    private let barCount = 24

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(isPlayed(index) ? 1 : (isActive ? 0.35 : 0.65)))
                    .frame(width: 3, height: height(at: index))
            }
        }
        .animation(.linear(duration: 0.15), value: progress)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }

    private func isPlayed(_ index: Int) -> Bool {
        isActive && Double(index) < progress * Double(barCount)
    }

    private func height(at index: Int) -> CGFloat {
        var generator = SeededGenerator(seed: UInt64(bitPattern: Int64(seed &+ index &* 7919)))
        return CGFloat(Double.random(in: 0.25...1, using: &generator)) * 26 + 2
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        var mixed = seed &+ 0x9E37_79B9_7F4A_7C15
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        mixed ^= mixed >> 31
        state = mixed == 0 ? 0x9E37_79B9_7F4A_7C15 : mixed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
