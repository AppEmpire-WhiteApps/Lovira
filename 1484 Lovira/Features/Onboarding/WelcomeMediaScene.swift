import SwiftUI

/// A chat exchange, not a second set of controls over the native onboarding builder.
struct WelcomeMediaScene: View {
    let float: CGFloat

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var captionSize: CGFloat = 12

    private let waveform: [CGFloat] = [8, 16, 24, 12, 20, 28, 16, 10, 22, 30, 18, 12, 24, 16]

    var body: some View {
        GeometryReader { geometry in
            let minimumPhotoHeight = max(96, captionSize * 3 + 16)
            let photoHeight = max(minimumPhotoHeight, min(216, geometry.size.height - 136))
            let needsOverflow = dynamicTypeSize > .large || geometry.size.height < 232

            Group {
                if needsOverflow {
                    ScrollView(.vertical) {
                        exchange(photoHeight: photoHeight)
                            .padding(.vertical, 4)
                    }
                } else {
                    exchange(photoHeight: photoHeight)
                        .offset(y: float)
                }
            }
            .frame(maxWidth: 380, maxHeight: .infinity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding.media.exchange")
    }

    private func exchange(photoHeight: CGFloat) -> some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                photo(
                    asset: "mia_01",
                    caption: LocalizedText("Mia · Photo", ru: "Мия · Фото"),
                    height: photoHeight
                )
                photo(
                    asset: "sofia_01",
                    caption: LocalizedText("Photo sent", ru: "Фото отправлено"),
                    height: max(96, captionSize * 3 + 16, photoHeight * 0.82)
                )
            }

            voiceReply
            textReply
        }
        .frame(maxWidth: 380)
    }

    private func photo(asset: String, caption: LocalizedText, height: CGFloat) -> some View {
        WelcomeBundledPhoto(asset: asset)
            .frame(height: height)
            .overlay(Theme.cardFade)
            .overlay(alignment: .bottomLeading) {
                Text(verbatim: caption.value)
                    .font(.poppins(12, .medium, relativeTo: .caption))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: WelcomeDesign.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: WelcomeDesign.cornerRadius)
                    .strokeBorder(Theme.pink.opacity(0.3), lineWidth: 1)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: caption.value))
    }

    private var voiceReply: some View {
        HStack(spacing: 8) {
            WelcomeBundledPhoto(asset: "mia_01")
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: LocalizedText("Mia · Voice message", ru: "Мия · Голосовое").value)
                    .font(.poppins(12, .medium, relativeTo: .caption))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 16)
                    ForEach(waveform.indices, id: \.self) { index in
                        Capsule()
                            .fill(Theme.pink)
                            .frame(maxWidth: 6)
                            .frame(height: waveform[index])
                    }
                }
                .foregroundStyle(Theme.pink)
                .frame(height: 30)
                .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(
            Theme.pinkBackground, in: RoundedRectangle(cornerRadius: WelcomeDesign.cornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: WelcomeDesign.cornerRadius)
                .strokeBorder(Theme.pink.opacity(0.3), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            Text(verbatim: LocalizedText("A voice reply from Mia", ru: "Голосовой ответ от Мии").value)
        )
    }

    private var textReply: some View {
        Text(
            verbatim: LocalizedText(
                "So lovely to hear from you 💕",
                ru: "Как приятно тебя слышать 💕"
            ).value
        )
        .font(.poppins(13, relativeTo: .subheadline))
        .foregroundStyle(.white)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: WelcomeDesign.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: WelcomeDesign.cornerRadius)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        }
    }
}

#Preview("Compact media background") {
    WelcomeScreenBackground(page: .media, contentSize: CGSize(width: 375, height: 623), topInset: 0)
        .frame(width: 375, height: 623)
}

#Preview("Short landscape media background") {
    WelcomeScreenBackground(page: .media, contentSize: CGSize(width: 756, height: 354), topInset: 0)
        .frame(width: 756, height: 354)
}

#Preview("Accessible media exchange") {
    WelcomeMediaScene(float: 0)
        .environment(\.dynamicTypeSize, .accessibility3)
        .frame(width: 327, height: 250)
}
