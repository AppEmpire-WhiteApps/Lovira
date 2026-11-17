import SwiftUI

/// Presented by the root cover through `AppModel.editingCharacter`.
struct EditCharacterView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    let character: CustomCharacter
    @State private var wizard: CreateWizardModel
    @State private var saveError: String?

    private let contentMaxWidth: CGFloat = 640

    init(character: CustomCharacter) {
        self.character = character
        _wizard = State(initialValue: CreateWizardModel(character: character))
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .frame(maxWidth: contentMaxWidth)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    CreateStepContent(wizard: wizard, editingCharacter: character)
                }
                .frame(maxWidth: contentMaxWidth)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .id(wizard.step)

            bottomBar
        }
        .background(Theme.background.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: wizard.step)
        .onDisappear {
            model.speech.stop()
        }
        .alert(
            LocalizedText("Couldn't save changes", ru: "Не удалось сохранить изменения").value,
            isPresented: Binding(
                get: { saveError != nil },
                set: { isPresented in
                    if !isPresented {
                        saveError = nil
                    }
                }
            )
        ) {
            Button(LocalizedText("OK", ru: "ОК").value, role: .cancel) {
                saveError = nil
            }
        } message: {
            Text(saveError ?? "")
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            if wizard.step != .summary {
                CircleIconButton(systemName: "chevron.left", size: 40) {
                    Haptics.tap()
                    wizard.jump(to: .summary)
                }
                .accessibilityLabel(LocalizedText("Overview", ru: "Обзор").value)
            }

            Text(LocalizedText("Edit character", ru: "Редактировать персонажа").value)
                .font(.appH3)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            CircleIconButton(systemName: "xmark", size: 40, action: close)
                .accessibilityLabel(LocalizedText("Cancel", ru: "Отмена").value)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(
                wizard.step == .summary
                    ? LocalizedText("Your character", ru: "Твой персонаж").value
                    : wizard.step.title
            )
            .font(.appTitle)
            .foregroundStyle(.white)

            Text(
                wizard.step == .summary
                    ? LocalizedText("Tap a field to change it", ru: "Нажми на поле, чтобы изменить его").value
                    : wizard.step.subtitle
            )
            .font(.appSubheadline)
            .foregroundStyle(Theme.textSecondary)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if !model.access.isPremium {
                Text(LocalizedText("Editing requires Premium", ru: "Для редактирования нужен Premium").value)
                    .font(.appCaption)
                    .foregroundStyle(Theme.textSecondary)
            }

            PrimaryButton(
                title: LocalizedStringKey(LocalizedText("Save changes", ru: "Сохранить изменения").value),
                icon: "checkmark",
                isEnabled: wizard.canSaveCharacter,
                action: save
            )
        }
        .frame(maxWidth: contentMaxWidth)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Theme.background)
    }

    private func save() {
        guard model.authorize(.characterEdit) else {
            return
        }
        model.speech.stop()
        do {
            guard try wizard.saveChanges(to: character, using: model) else {
                return
            }
            Haptics.success()
            dismiss()
        } catch {
            saveError =
                LocalizedText(
                    "Your changes weren't saved. Please try again. Your existing character is unchanged.",
                    ru: "Изменения не сохранены. Попробуй ещё раз. Существующий персонаж не изменился."
                ).value
            Haptics.warning()
        }
    }

    private func close() {
        model.speech.stop()
        dismiss()
    }
}
