import SwiftUI

extension View {
    /// Apply to the active top presenter so the prompt covers its interactive content.
    @MainActor
    func aiConsentPresentation(active: Bool = true) -> some View {
        modifier(AIConsentPresentationModifier(active: active))
    }
}

@MainActor
private struct AIConsentPresentationModifier: ViewModifier {
    let active: Bool
    private let store = AIConsentStore.shared

    private var showsPrompt: Bool {
        active && store.isPresented
    }

    func body(content: Content) -> some View {
        content
            .disabled(showsPrompt)
            .allowsHitTesting(!showsPrompt)
            .accessibilityHidden(showsPrompt)
            .overlay {
                if showsPrompt {
                    AIConsentAlert()
                }
            }
    }
}

@MainActor
struct AIConsentAlert: View {
    private let store = AIConsentStore.shared
    @AccessibilityFocusState private var isTitleFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Theme.background.opacity(0.82)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {}
                    .accessibilityHidden(true)

                ViewThatFits(in: .vertical) {
                    alertContent(stackedActions: usesStackedActions(in: geometry.size.width))
                    ScrollView {
                        alertContent(stackedActions: usesStackedActions(in: geometry.size.width))
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
                .frame(maxWidth: 420)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Theme.stroke, lineWidth: 1)
                }
                .padding(24)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .accessibilityElement(children: .contain)
                .accessibilityAddTraits(.isModal)
                .accessibilityIdentifier("aiConsent.alert")
                .accessibilityAction(.escape) {
                    store.cancel()
                }
            }
        }
        .task {
            isTitleFocused = true
        }
    }

    private func usesStackedActions(in width: CGFloat) -> Bool {
        dynamicTypeSize.isAccessibilitySize || width < 390
    }

    private func alertContent(stackedActions: Bool) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(LocalizedText("AI Data Processing", ru: "Обработка данных с помощью ИИ").value)
                .font(.appH3)
                .foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($isTitleFocused)
                .accessibilityIdentifier("aiConsent.title")

            Text(
                LocalizedText(
                    "To process AI requests, the app sends your text, chat context and memory, images, audio, and character descriptions to LLMApps and its AI model providers.",
                    ru:
                        "Для обработки запросов к ИИ приложение отправляет ваши тексты, контекст и память чатов, изображения, аудио и описания персонажей в LLMApps и поставщикам используемых им моделей ИИ."
                ).value
            )
            .font(.appBody)
            .foregroundStyle(Theme.textSecondary)
            .accessibilityIdentifier("aiConsent.disclosure")

            Text(
                LocalizedText(
                    "By tapping Continue, you consent to sharing this data with LLMApps and its AI model providers to process your AI requests. You can tap Cancel to decline.",
                    ru:
                        "Нажимая «Продолжить», вы соглашаетесь на передачу этих данных в LLMApps и поставщикам используемых им моделей ИИ для обработки ваших запросов. Чтобы отказаться, нажмите «Отмена»."
                ).value
            )
            .font(.appBody)
            .foregroundStyle(Theme.textSecondary)
            .accessibilityIdentifier("aiConsent.confirmation")

            actionButtons(stacked: stackedActions)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(24)
    }

    private func actionButtons(stacked: Bool) -> some View {
        let layout =
            stacked
            ? AnyLayout(VStackLayout(spacing: 12))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))

        return layout {
            cancelButton
            continueButton
        }
    }

    private var cancelButton: some View {
        Button(role: .cancel) {
            store.cancel()
        } label: {
            Text(LocalizedText("Cancel", ru: "Отмена").value)
                .font(.appBodyMedium)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityIdentifier("aiConsent.cancel")
    }

    private var continueButton: some View {
        Button(action: store.accept) {
            Text(LocalizedText("Continue", ru: "Продолжить").value)
                .font(.poppins(16, .semibold, relativeTo: .body))
                .foregroundStyle(Theme.background)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Theme.pink, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityIdentifier("aiConsent.continue")
    }
}
