import SwiftUI

struct ProfilePremiumBanner: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isPremium: Bool {
        model.access.isPremium
    }

    private var title: String {
        isPremium
            ? LocalizedText("Scenarios", ru: "Сценарии").value
            : LocalizedText("Premium", ru: "Premium").value
    }

    private var subtitle: String {
        isPremium
            ? LocalizedText(
                "Set the scene for your next conversation",
                ru: "Выбери сюжет для следующего разговора"
            ).value
            : LocalizedText(
                "More connection, fewer limits",
                ru: "Больше близости, меньше ограничений"
            ).value
    }

    private var accessibilityLabel: String {
        "\(title), \(subtitle)"
    }

    private var actionTitle: String {
        isPremium
            ? LocalizedText("Explore scenarios", ru: "Смотреть сценарии").value
            : LocalizedText("Explore Premium", ru: "Открыть Premium").value
    }

    private var accessibilityHint: String {
        isPremium
            ? LocalizedText("Opens the Scenarios offer", ru: "Открывает предложение для сценариев").value
            : LocalizedText("Opens Premium plans", ru: "Открывает тарифы Premium").value
    }

    var body: some View {
        Button {
            model.showPaywall(model.access.isPremium ? .scenarios : .main)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: title)
                        .font(.appH3)
                        .foregroundStyle(Theme.textPrimary)

                    Text(verbatim: subtitle)
                        .font(.appSubheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .lineSpacing(2)
                }

                HStack(spacing: 6) {
                    Text(verbatim: actionTitle)

                    Image(systemName: "arrow.right")
                        .accessibilityHidden(true)
                }
                .font(.appCaptionBold)
                .foregroundStyle(Theme.pink)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.trailing, dynamicTypeSize.isAccessibilitySize ? 0 : 64)
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
            .background { artworkBackground }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Theme.pink.opacity(0.18), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: accessibilityLabel))
        .accessibilityHint(Text(verbatim: accessibilityHint))
        .accessibilityIdentifier(isPremium ? "profile.premiumBanner.scenarios" : "profile.premiumBanner.main")
    }

    private var artworkBackground: some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                Theme.surface

                if !dynamicTypeSize.isAccessibilitySize {
                    Image(isPremium ? "ScenariosCollage" : "MainCollage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width * 0.64, height: geometry.size.height)
                        .opacity(0.8)
                }

                LinearGradient(
                    stops: [
                        .init(color: Theme.surface, location: 0),
                        .init(color: Theme.surface, location: 0.36),
                        .init(color: Theme.surface.opacity(0.94), location: 0.64),
                        .init(color: Theme.surface.opacity(0.72), location: 0.8),
                        .init(color: Theme.pinkBackground.opacity(0.2), location: 1),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
