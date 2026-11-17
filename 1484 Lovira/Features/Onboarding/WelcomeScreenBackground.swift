import SwiftUI

/// A screen background only. PremiumKit draws every heading, message, button and footer above it.
struct WelcomeScreenBackground: View {
    let page: WelcomePage
    let contentSize: CGSize
    let topInset: CGFloat

    private var layout: WelcomeLayout {
        WelcomeLayout(size: contentSize)
    }

    private var artworkHeight: CGFloat {
        max(0, contentSize.height - WelcomeDesign.onboardingContentHeight(scale: layout.scale) - layout.gap * 2)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.background
            WelcomeScene(kind: page.scene)
                .frame(height: artworkHeight)
                .padding(.horizontal, 24)
                .padding(.top, topInset + layout.gap)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("onboarding.scene.\(page.rawValue + 1)")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension WelcomeDesign {
    /// Conservative space for the native builder: two title lines and up to three subtitle lines.
    static func onboardingContentHeight(scale: CGFloat) -> CGFloat {
        let title = max(24, 28 * scale) * 1.2 * 2
        let subtitle = max(14, 15 * scale) * 1.2 * 3
        let message = max(44, 48 * scale)
        let buttonAndLinks = max(44, 52 * scale) + 6 + 20
        let indicators: CGFloat = 6
        let spacing = 12 * scale * 4
        let bottom: CGFloat = 12
        return title + subtitle + message + buttonAndLinks + indicators + spacing + bottom
    }
}

#Preview("Compact reviews background") {
    WelcomeScreenBackground(page: .reviews, contentSize: CGSize(width: 375, height: 623), topInset: 0)
        .frame(width: 375, height: 623)
}
