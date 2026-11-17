import PremiumKit
import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var model = model

        ZStack {
            Theme.background.ignoresSafeArea()

            if !model.profile.hasOnboarded {
                PremiumOnboardingScreen()
                    .transition(.opacity)
            } else if !model.profile.hasConfirmedAge {
                AgeGateView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
                    .taskOnce {
                        await model.loadMainPaywall()
                    }
            }

            if model.profile.appLockEnabled && scenePhase != .active && !model.lock.isLocked {
                PrivacyCurtain()
            }

            if model.lock.isLocked {
                LockView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .overlay(alignment: .top) {
            if let toast = model.toast {
                ToastView(text: toast.text, icon: toast.icon)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(3)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: model.profile.hasConfirmedAge)
        .animation(.easeInOut(duration: 0.35), value: model.profile.hasOnboarded)
        .animation(.easeInOut(duration: 0.25), value: model.lock.isLocked)
        .taskOnce {
            await model.loadScenarioPaywall()
        }
        .fullScreenCover(isPresented: $model.isCreatePresented) {
            CreateCharacterView()
                .premiumPresentation()
                .aiConsentPresentation(active: model.paywallRoute == nil)
        }
        .fullScreenCover(item: $model.editingCharacter) { character in
            EditCharacterView(character: character)
                .premiumPresentation()
                .aiConsentPresentation(active: model.paywallRoute == nil)
        }
        .premiumPresentation(active: !model.isCreatePresented && model.editingCharacter == nil)
        .aiConsentPresentation(
            active: !model.isCreatePresented && model.editingCharacter == nil
                && model.paywallRoute == nil && !model.lock.isLocked
        )
        .onChange(of: model.access.isPremium) { _, premium in
            if !premium {
                model.speech.stop()
                model.voicePlayer.stop()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                if model.profile.appLockEnabled {
                    model.lock.lock()
                }
                model.speech.stop()
            case .active:
                model.purgeExpiredMessages()
                if model.lock.isLocked {
                    Task {
                        await model.lock.unlock()
                    }
                }
            default:
                break
            }
        }
    }
}

private struct PrivacyCurtain: View {
    var body: some View {
        ZStack {
            Theme.background
            Image(systemName: "heart.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Theme.ctaGradient)
        }
        .ignoresSafeArea()
    }
}

struct LockView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            RadialGradient(
                colors: [Theme.pink.opacity(0.25), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 320
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "lock.heart.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Theme.ctaGradient)
                Text("Your chats are protected")
                    .font(.appSubheadline)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                PrimaryButton(
                    title: LocalizedStringKey(
                        LocalizedText(
                            "Unlock with \(AppLock.biometryName)", ru: "Разблокировать: \(AppLock.biometryName)"
                        ).value),
                    icon: "faceid"
                ) {
                    Task {
                        await model.lock.unlock()
                    }
                }
                .frame(maxWidth: 420)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .task {
            await model.lock.unlock()
        }
    }
}
