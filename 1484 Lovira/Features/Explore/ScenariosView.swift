import SwiftUI

struct ScenariosView: View {
    let companionId: String

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var columns: [GridItem] {
        if sizeClass == .regular {
            return [GridItem(.adaptive(minimum: 300, maximum: 420), spacing: 14)]
        }
        return [GridItem(.flexible())]
    }

    var body: some View {
        Group {
            if let companion = model.companion(id: companionId) {
                content(for: companion)
            } else {
                EmptyStateView(
                    icon: "person.crop.circle.badge.questionmark",
                    title: "Character not found",
                    message: "She may have been deleted."
                )
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private func content(for companion: Companion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(companion)
                Text("Pick a story and she will play along. Each scene starts with her first line.")
                    .font(.appSubheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Scenario.all) { scenario in
                        Button {
                            Haptics.tap()
                            guard model.authorize(.scenarios) else {
                                return
                            }
                            model.startScenario(scenario, with: companion)
                        } label: {
                            ScenarioCard(scenario: scenario, isLocked: !model.access.hasScenarioAccess)
                        }
                        .buttonStyle(PressableButtonStyle())
                        .accessibilityIdentifier("scenario.\(scenario.id)")
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    private func header(_ companion: Companion) -> some View {
        HStack(spacing: 12) {
            CircleIconButton(systemName: "chevron.left") {
                dismiss()
            }
            .accessibilityLabel(Text("Back"))
            AvatarView(source: companion.avatar, size: 44, showsOnline: true)
            VStack(alignment: .leading, spacing: 0) {
                Text("Scenarios")
                    .font(.appH2)
                    .foregroundStyle(.white)
                Text(LocalizedText("Roleplay with \(companion.name)", ru: "Ролевая игра с \(companion.name)").value)
                    .font(.appCaption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
    }
}

private struct ScenarioCard: View {
    let scenario: Scenario
    let isLocked: Bool

    var body: some View {
        let tint = Color(hex: scenario.tint)
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.45)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: scenario.icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 64, height: 64)
            .shadow(color: tint.opacity(0.4), radius: 10, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: scenario.title.value)
                    .font(.poppins(16, .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: scenario.subtitle.value)
                    .font(.appCaption)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: isLocked ? "lock.fill" : "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.pink)
                .accessibilityLabel(Text(LocalizedText(
                    isLocked ? "Premium scenario" : "Start scenario",
                    ru: isLocked ? "Сценарий по подписке" : "Начать сценарий"
                ).value))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(Theme.surface)
                .overlay(alignment: .leading) {
                    LinearGradient(
                        colors: [tint.opacity(0.18), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        }
    }
}
