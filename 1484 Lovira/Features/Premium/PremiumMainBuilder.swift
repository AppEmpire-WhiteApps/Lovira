import PremiumKit
import SwiftUI

struct PremiumMainBuilder: View {
    let dismiss: () -> Void

    var body: some View {
        GeometryReader { proxy in
            PaywallBuilder(
                images: WelcomeDesign.mainImages,
                style: WelcomeDesign.mainStyle(scale: WelcomeLayout(size: proxy.size).scale),
                linksConfig: WelcomeDesign.links,
                termsView: { WelcomeLegalScreen(document: .terms) },
                privacyView: { WelcomeLegalScreen(document: .privacy) },
                backgroundView: AnyView(Theme.background),
                middleView: AnyView(PremiumArtwork(kind: .premium)),
                secondaryPaywallView: AnyView(PremiumScenariosBuilder(dismiss: dismiss)),
                onDismiss: dismiss,
                onSuccess: dismiss
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("paywall.main")
    }
}

struct PremiumScenariosBuilder: View {
    let dismiss: () -> Void

    var body: some View {
        GeometryReader { proxy in
            SecondaryPaywallBuilder(
                paywallID: PremiumRoute.scenarios.paywallID,
                images: WelcomeDesign.scenariosImages,
                style: WelcomeDesign.secondaryStyle(scale: WelcomeLayout(size: proxy.size).scale),
                linksConfig: WelcomeDesign.links,
                showCloseButton: false,
                termsView: { WelcomeLegalScreen(document: .terms) },
                privacyView: { WelcomeLegalScreen(document: .privacy) },
                backgroundView: AnyView(Theme.background),
                middleView: AnyView(PremiumArtwork(kind: .scenarios)),
                onDismiss: dismiss,
                onSuccess: {
                    if Premium.shared.hasActiveProduct(fromPaywall: PremiumRoute.scenarios.paywallID) {
                        dismiss()
                    }
                }
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("paywall.scenarios")
    }
}

/// Only the artwork slot is app-owned; titles, offers, trial controls and purchases stay in PremiumKit.
struct PremiumArtwork: View {
    let kind: WelcomeSceneKind

    var body: some View {
        WelcomeScene(kind: kind)
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
