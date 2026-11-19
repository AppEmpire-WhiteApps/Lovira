import PremiumKit
import SwiftUI

struct PremiumPaywallScreen: View {
    let route: PremiumRoute
    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            switch route {
            case .main:
                PremiumMainBuilder { model.paywallRoute = nil }
            case .scenarios:
                PremiumScenariosBuilder { model.paywallRoute = nil }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct PremiumOnboardingScreen: View {
    @Environment(AppModel.self) private var model
    @State private var limitedCompletion = false

    var body: some View {
        GeometryReader { proxy in
            let contentHeight = max(proxy.size.height, 580)
            ScrollView(.vertical) {
                configuredOnboarding(
                    size: CGSize(width: proxy.size.width, height: contentHeight),
                    topInset: proxy.safeAreaInsets.top
                )
                .frame(height: contentHeight)
            }
            .scrollDisabled(proxy.size.height >= contentHeight)
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.dark)
        .taskOnce {
            await Premium.shared.loadPaywall(.onboarding)
        }
    }

    private func configuredOnboarding(size: CGSize, topInset: CGFloat) -> some View {
        let scale = WelcomeLayout(size: size).scale
        return OnboardingBuilder(
            screens: [WelcomePage.conversation, .companions, .reviews, .media].map {
                screen($0, size: size, topInset: topInset)
            },
            paywallImages: WelcomeDesign.mainImages,
            style: WelcomeDesign.onboardingStyle(scale: scale),
            linksConfig: WelcomeDesign.links,
            showReviewRequestOnComplete: true,
            termsView: { WelcomeLegalScreen(document: .terms) },
            privacyView: { WelcomeLegalScreen(document: .privacy) },
            paywallBackgroundView: AnyView(Theme.background),
            paywallMiddleView: AnyView(PremiumArtwork(kind: .premium)),
            secondaryPaywallID: PremiumRoute.scenarios.paywallID,
            secondaryPaywallImages: WelcomeDesign.scenariosImages,
            secondaryPaywallBackgroundView: AnyView(Theme.background),
            secondaryPaywallMiddleView: AnyView(PremiumArtwork(kind: .scenarios)),
            onLimitedTapped: { limitedCompletion = true },
            onSecondaryLimitedTapped: { limitedCompletion = true },
            onComplete: {
                if limitedCompletion || Premium.shared.isPremium {
                    model.profile.hasOnboarded = true
                }
            }
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding")
    }

    private func screen(_ page: WelcomePage, size: CGSize, topInset: CGFloat) -> OnboardingScreen {
        let lines = page.title.components(separatedBy: "\n")
        return OnboardingScreen(
            id: page.rawValue,
            title1: lines[0],
            title2: lines[1],
            subtitle: page.subtitle,
            message: page.message,
            buttonTitle: LocalizedText("Continue", ru: "Продолжить").value,
            images: WelcomeDesign.images(for: page.scene),
            backgroundView: AnyView(WelcomeScreenBackground(page: page, contentSize: size, topInset: topInset))
        )
    }
}

/// Attach to the active top-level presentation, never present from the obscured root controller.
struct PremiumPresentation: ViewModifier {
    @Environment(AppModel.self) private var model
    let active: Bool

    func body(content: Content) -> some View {
        content.fullScreenCover(
            item: Binding(
                get: { active ? model.paywallRoute : nil },
                set: { if active { model.paywallRoute = $0 } }
            )
        ) { route in
            PremiumPaywallScreen(route: route)
        }
    }
}

extension View {
    func premiumPresentation(active: Bool = true) -> some View {
        modifier(PremiumPresentation(active: active))
    }
}
