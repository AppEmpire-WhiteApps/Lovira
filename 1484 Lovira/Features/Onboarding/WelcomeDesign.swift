import PremiumKit
import SwiftUI

enum WelcomeDesign {
    static let cornerRadius: CGFloat = 8
    static let buttonColor = Color(hex: 0xC92F58)

    static var links: LinksConfiguration {
        LinksConfiguration(
            termsTitle: LocalizedText("Terms of Use", ru: "Условия").value,
            privacyTitle: LocalizedText("Privacy Policy", ru: "Конфиденциальность").value,
            restoreTitle: LocalizedText("Restore", ru: "Восстановить").value,
            order: [.terms, .restore, .privacy]
        )
    }

    static var mainImages: AdaptiveResources {
        AdaptiveResources(iphone: Image("MainCollage"))
    }

    static var scenariosImages: AdaptiveResources {
        AdaptiveResources(iphone: Image("ScenariosCollage"))
    }

    static func images(for scene: WelcomeSceneKind) -> AdaptiveResources {
        switch scene {
        case .conversation: AdaptiveResources(iphone: Image("mia_01"))
        case .companions, .reviews: AdaptiveResources(iphone: Image("sofia_01"))
        case .media: AdaptiveResources(iphone: Image("mia_01"))
        case .premium: mainImages
        case .scenarios: scenariosImages
        }
    }

    static func onboardingStyle(scale: CGFloat) -> OnboardingStyle {
        OnboardingStyle(
            limitedButtonUnderline: false,
            limitedButtonFont: .system(size: max(14, 15 * scale)),
            limitedButtonColor: Theme.textSecondary,
            toggleColor: Theme.pink,
            backgroundColor: Theme.background,
            titleFont: .system(size: max(24, 28 * scale), weight: .bold),
            titleFixedSize: true,
            subtitleFixedSize: true,
            title1Color: Color.white,
            title2Color: Color.white,
            subtitleFont: .system(size: max(14, 15 * scale)),
            subtitleColor: Theme.textSecondary,
            messageFont: .system(size: max(13, 14 * scale), weight: .medium),
            messageColor: Color.white,
            messageBackgroundColor: Theme.pinkBackground,
            messageHeight: max(44, 48 * scale),
            messageCornerRadius: cornerRadius,
            messageBorderColor: Theme.pink.opacity(0.3),
            messageShowBorder: true,
            buttonFont: .system(size: max(16, 17 * scale), weight: .semibold),
            buttonTextColor: Color.white,
            buttonBackgroundColor: buttonColor,
            buttonCornerRadius: cornerRadius,
            buttonHeight: max(44, 52 * scale),
            showPaywallButtonAnimation: false,
            linksFont: .system(size: 12),
            linksColor: Theme.textSecondary,
            linksSpacing: 12,
            linksShowDividers: false,
            contentSpacing: 12 * scale,
            horizontalPadding: 24,
            bottomPadding: 12,
            maxWidth: 520,
            indicatorActiveColor: Theme.pink,
            indicatorInactiveColor: Theme.pink.opacity(0.4),
            indicatorFutureColor: Theme.stroke,
            indicatorActiveWidth: 22,
            indicatorInactiveWidth: 6,
            indicatorHeight: 6,
            indicatorSpacing: 6,
            showNewToggle: true,
            toggleType: .checkmark,
            checkmarkActiveBGColor: Theme.pinkDark,
            checkmarkActiveColor: Color.white,
            checkmarkInactiveBorderColor: Theme.textSecondary,
            minimumScaleFactor: 0.85
        )
    }

    static func mainStyle(scale: CGFloat) -> PaywallStyle {
        PaywallStyle(
            accentColor: Theme.pink,
            backgroundColor: Theme.background,
            titleOrder: .titleFirst,
            titleFont: .system(size: max(24, 28 * scale), weight: .bold),
            titleColor: Color.white,
            subtitleFont: .system(size: max(13, 14 * scale)),
            subtitleColor: Theme.textSecondary,
            titleSubtitleSpacing: 6,
            buttonFont: .system(size: 17, weight: .semibold),
            buttonTextColor: Color.white,
            buttonBackgroundColor: buttonColor,
            buttonCornerRadius: cornerRadius,
            buttonHeight: max(44, 52 * scale),
            linksFont: .system(size: 12),
            linksColor: Theme.textSecondary,
            linksSpacing: 12,
            linksShowDividers: false,
            contentSpacing: 10 * scale,
            horizontalPadding: 24,
            bottomPadding: 12,
            maxWidth: 520,
            offerHeight: max(48, 54 * scale),
            offerCornerRadius: cornerRadius,
            offerSpacing: 8,
            offerTitleFont: .system(size: 15, weight: .semibold),
            offerTitleColor: Color.white,
            offerSelectedTitleFont: .system(size: 15, weight: .semibold),
            offerSelectedTitleColor: Color.white,
            offerSubtitleColor: Theme.textSecondary,
            offerSelectedSubtitleColor: Theme.textSecondary,
            offerPriceColor: Color.white,
            offerSelectedPriceColor: Color.white,
            offerBorderColor: Theme.stroke,
            offerSelectedBorderColor: Theme.pink,
            offerBorderWidth: 1,
            offerSelectedBorderWidth: 1,
            offerBackgroundColor: Theme.surface,
            offerSelectedBackgroundColor: Theme.pinkBackground,
            offerCheckmarkActiveBGColor: Theme.pinkDark,
            offerCheckmarkInactiveBGColor: Color.clear,
            offerCheckmarkInactiveBorderColor: Theme.textSecondary.opacity(0.45),
            closeButtonIcon: "xmark",
            closeButtonColor: Color.white,
            closeButtonFont: .system(size: 14, weight: .semibold),
            closeButtonPlacement: .topBarTrailing,
            closeButtonShowGlass: false
        )
    }

    static func secondaryStyle(scale: CGFloat) -> SecondaryPaywallStyle {
        var style = SecondaryPaywallStyle()
        style.contentBackground.backgroundColor = AnyShapeStyle(Theme.background)
        style.title.font = .system(size: max(24, 28 * scale), weight: .bold)
        style.title.color1 = AnyShapeStyle(Color.white)
        style.title.color2 = AnyShapeStyle(Color.white)
        style.title.subtitleColor = AnyShapeStyle(Theme.textSecondary)
        style.title.limitedButtonUnderline = false
        style.messageToggle.color = AnyShapeStyle(Color.white)
        style.messageToggle.backgroundColor = AnyShapeStyle(Theme.pinkBackground)
        style.messageToggle.cornerRadius = cornerRadius
        style.messageToggle.height = max(44, 48 * scale)
        style.messageToggle.showNewToggle = true
        style.messageToggle.toggleType = .checkmark
        style.messageToggle.checkmarkActiveBGColor = AnyShapeStyle(Theme.pinkDark)
        style.button.textColor = AnyShapeStyle(Color.white)
        style.button.backgroundColor = AnyShapeStyle(buttonColor)
        style.button.cornerRadius = cornerRadius
        style.button.height = max(44, 52 * scale)
        style.offer.cornerRadius = cornerRadius
        style.offer.titleColor = AnyShapeStyle(Color.white)
        style.offer.selectedTitleColor = AnyShapeStyle(Color.white)
        style.offer.subtitleColor = AnyShapeStyle(Theme.textSecondary)
        style.offer.selectedSubtitleColor = AnyShapeStyle(Theme.textSecondary)
        style.offer.priceColor = AnyShapeStyle(Color.white)
        style.offer.selectedPriceColor = AnyShapeStyle(Color.white)
        style.offer.backgroundColor = AnyShapeStyle(Theme.surface)
        style.offer.selectedBackgroundColor = AnyShapeStyle(Theme.pinkBackground)
        style.offer.selectedBorderColor = AnyShapeStyle(Theme.pink)
        style.links.color = AnyShapeStyle(Theme.textSecondary)
        style.links.showDividers = false
        style.layout.horizontalPadding = 24
        style.layout.bottomPadding = 12
        style.layout.maxWidth = 520
        style.closeButton.placement = .topBarTrailing
        style.closeButton.showGlass = false
        return style
    }
}

struct WelcomeLayout {
    let scale: CGFloat
    let gap: CGFloat

    init(size: CGSize) {
        scale = min(1.15, max(0.86, min(size.width / 390, size.height / 740)))
        gap = max(16, 24 * scale)
    }
}
