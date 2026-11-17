import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var page = 0
    @FocusState private var isNameFocused: Bool

    private let pageCount = 5

    var body: some View {
        @Bindable var profile = model.profile

        VStack(spacing: 0) {
            TabView(selection: $page) {
                OnboardingPage(
                    title: "She understands you",
                    subtitle: "Talk about anything. An AI girl who listens, supports and remembers what matters to you."
                ) {
                    DialogIllustration()
                }
                .tag(0)

                OnboardingPage(
                    title: "Your type, your rules",
                    subtitle: "Choose who you want to talk to today — or create the girl of your dreams."
                ) {
                    FacesIllustration(companions: Array(model.presets.prefix(4)))
                }
                .tag(1)

                OnboardingPage(
                    title: "Voice & emotions",
                    subtitle: "Send voice messages and hear warmth in every reply."
                ) {
                    VoiceIllustration(avatar: .asset("elena_01"))
                }
                .tag(2)

                OnboardingPage(
                    title: "Gallery of moments",
                    subtitle: "Collect her photos and videos as you get closer."
                ) {
                    GalleryIllustration()
                }
                .tag(3)

                personalization(profile: profile)
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)

            VStack(spacing: 18) {
                PageDots(count: pageCount, current: page)
                PrimaryButton(title: page == pageCount - 1 ? "Start" : "Continue") {
                    advance()
                }
            }
            .frame(maxWidth: 460)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(Theme.background.ignoresSafeArea())
        .onTapGesture {
            isNameFocused = false
        }
    }

    private func personalization(profile: UserProfile) -> some View {
        @Bindable var profile = profile
        return ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Spacer(minLength: 30)
                Text("Let's get to know each other")
                    .font(.appTitle)
                    .foregroundStyle(.white)
                Text("What should she call you?")
                    .font(.appCallout)
                    .foregroundStyle(Theme.textSecondary)
                TextField("Your name", text: $profile.userName)
                    .font(.appBody)
                    .foregroundStyle(.white)
                    .textInputAutocapitalization(.words)
                    .focused($isNameFocused)
                    .padding(.horizontal, 18)
                    .frame(height: 56)
                    .background(Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .submitLabel(.done)

                Text("What are you looking for?")
                    .font(.appCallout)
                    .foregroundStyle(Theme.textSecondary)
                VStack(spacing: 10) {
                    ForEach(LookingFor.allCases) { option in
                        let isSelected = profile.lookingFor == option
                        Button {
                            Haptics.tap()
                            profile.lookingFor = option
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: option.icon)
                                    .font(.system(size: 18))
                                    .foregroundStyle(isSelected ? AnyShapeStyle(Theme.ctaGradient) : AnyShapeStyle(Theme.textSecondary))
                                    .frame(width: 28)
                                Text(verbatim: option.title)
                                    .font(.appBodyMedium)
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isSelected ? Theme.pink : Theme.textTertiary)
                            }
                            .padding(.horizontal, 18)
                            .frame(height: 58)
                            .background(isSelected ? Theme.pinkBackground : Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(isSelected ? Theme.pink : .clear, lineWidth: 1.5)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: 460, alignment: .leading)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func advance() {
        Haptics.tap()
        if page < pageCount - 1 {
            withAnimation {
                page += 1
            }
            return
        }
        isNameFocused = false
        model.profile.hasOnboarded = true
    }
}

private struct OnboardingPage<Illustration: View>: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    @ViewBuilder let illustration: () -> Illustration

    var body: some View {
        VStack(spacing: 20) {
            illustration()
                .frame(maxWidth: 460, maxHeight: .infinity)
                .padding(.top, 20)
            VStack(spacing: 10) {
                Text(title)
                    .font(.appTitle)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.appBody)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 460)
            .padding(.horizontal, 28)
            .padding(.bottom, 12)
        }
    }
}

private struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? AnyShapeStyle(Theme.ctaGradient) : AnyShapeStyle(Theme.surfaceHigh))
                    .frame(width: index == current ? 24 : 8, height: 8)
            }
        }
        .animation(.spring(response: 0.3), value: current)
    }
}

private struct DialogIllustration: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            PhotoView(source: .asset("mia_01"), maxPixelSize: 1000)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(Theme.cardFade.clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous)))
            VStack(alignment: .leading, spacing: 8) {
                bubble(LocalizedText("Rough day at work…", ru: "Тяжёлый день на работе…").value, isUser: true)
                bubble(LocalizedText("Come here, tell me everything 💕 I'm all yours tonight", ru: "Иди сюда, расскажи всё 💕 Сегодня я только твоя").value, isUser: false)
            }
            .padding(16)
        }
        .padding(.horizontal, 24)
    }

    private func bubble(_ text: String, isUser: Bool) -> some View {
        HStack {
            if isUser {
                Spacer()
            }
            Text(verbatim: text)
                .font(.appSubheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    if isUser {
                        BubbleShape(isUser: true).fill(Theme.ctaGradient)
                    } else {
                        BubbleShape(isUser: false).fill(.ultraThinMaterial)
                    }
                }
            if !isUser {
                Spacer()
            }
        }
    }
}

private struct FacesIllustration: View {
    let companions: [Companion]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(companions) { companion in
                ZStack(alignment: .bottomLeading) {
                    PhotoView(source: companion.cover, maxPixelSize: 600)
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .overlay(Theme.cardFade)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: companion.name)
                            .font(.poppins(15, .semibold))
                        Text(verbatim: companion.traits.first?.title ?? "")
                            .font(.appCaption)
                            .foregroundStyle(Theme.pink)
                    }
                    .foregroundStyle(.white)
                    .padding(10)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct VoiceIllustration: View {
    let avatar: PhotoSource
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(Theme.pink.opacity(0.35 - Double(ring) * 0.1), lineWidth: 2)
                        .frame(width: 190 + CGFloat(ring) * 50, height: 190 + CGFloat(ring) * 50)
                        .scaleEffect(pulse ? 1.06 : 0.94)
                }
                AvatarView(source: avatar, size: 180)
            }
            HStack(spacing: 14) {
                Image(systemName: "play.fill")
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Theme.ctaGradient, in: Circle())
                Waveform(seed: 42, progress: 0.45, isActive: true)
                    .frame(height: 30)
                Text(verbatim: "0:12")
                    .font(.appCaption)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.surfaceHigh, in: Capsule())
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

private struct GalleryIllustration: View {
    private let photos = ["layla_05", "naomi_06", "chloe_04", "amara_08", "yuna_03", "sofia_06"]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(photos, id: \.self) { name in
                PhotoView(source: .asset(name), maxPixelSize: 400)
                    .aspectRatio(3 / 4, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(.horizontal, 24)
    }
}
