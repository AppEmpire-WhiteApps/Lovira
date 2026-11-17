import SwiftUI

/// Character creation wizard, presented full screen from the tab bar "+" button.
struct CreateCharacterView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var wizard = CreateWizardModel()
    @State private var generationTask: Task<Void, Never>?

    private let contentMaxWidth: CGFloat = 640

    var body: some View {
        ZStack {
            background

            switch wizard.phase {
            case .wizard:
                wizardContent
                    .transition(.opacity)
            case .generating:
                phaseContainer {
                    CreateGeneratingView(
                        title: LocalizedText("Creating \(wizard.trimmedName)…", ru: "Создаём \(wizard.trimmedName)…").value,
                        statuses: CreateGeneratingView.portraitStatuses,
                        placeholderCount: CreateWizardModel.portraitCount
                    )
                }
            case .picking:
                phaseContainer {
                    CreatePickPortraitView(
                        wizard: wizard,
                        onConfirm: finish,
                        onRegenerate: regenerate
                    )
                }
            case .finishing:
                phaseContainer {
                    CreateGeneratingView(
                        title: LocalizedText("Almost ready…", ru: "Почти готово…").value,
                        statuses: CreateGeneratingView.finishingStatuses,
                        placeholderCount: 0
                    )
                }
            case .failed(let failure):
                phaseContainer {
                    CreateErrorView(
                        message: failure.message,
                        onRetry: { retry(failure) },
                        onBack: backToWizard
                    )
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: wizard.phase)
        .onChange(of: wizard.savedCharacterID) { _, id in
            if let id {
                complete(characterID: id)
            }
        }
        .onDisappear {
            if !AIConsentStore.shared.hasGranted {
                AIConsentStore.shared.cancel(notifyCancellation: false)
            }
        }
        #if DEBUG
        .onAppear(perform: applyDebugGeneration)
        #endif
    }

    #if DEBUG
    /// `-debugCreateGenerate YES` fills the wizard and starts generation for simulator checks.
    private func applyDebugGeneration() {
        guard UserDefaults.standard.bool(forKey: "debugCreateGenerate"), wizard.phase == .wizard else {
            return
        }
        wizard.ethnicity = .latina
        wizard.traits = [.playful, .romantic]
        wizard.interests = [.travel, .music]
        wizard.name = "Valentina"
        wizard.step = .summary
        generate()
    }
    #endif

    // MARK: Layout

    private var background: some View {
        ZStack {
            Theme.background
            RadialGradient(
                colors: [Theme.pink.opacity(0.16), .clear],
                center: .top,
                startRadius: 20,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }

    private var wizardContent: some View {
        VStack(spacing: 0) {
            topBar
                .frame(maxWidth: contentMaxWidth)
                .padding(.horizontal, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    CreateStepContent(wizard: wizard)
                }
                .frame(maxWidth: contentMaxWidth)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .id(wizard.step)
            .transition(stepTransition)

            bottomBar
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.88), value: wizard.step)
    }

    private var stepTransition: AnyTransition {
        let insertion: Edge = wizard.isMovingForward ? .trailing : .leading
        let removal: Edge = wizard.isMovingForward ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: insertion).combined(with: .opacity),
            removal: .move(edge: removal).combined(with: .opacity)
        )
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            CircleIconButton(systemName: "chevron.left", size: 40) {
                Haptics.tap()
                wizard.goBack()
            }
            .opacity(wizard.isFirstStep ? 0 : 1)
            .disabled(wizard.isFirstStep)
            .accessibilityLabel(Text("Back"))

            VStack(spacing: 6) {
                CreateProgressBar(progress: wizard.progress)
                Text(verbatim: "\(wizard.step.rawValue + 1) / \(CreateStep.allCases.count)")
                    .font(.appCaption)
                    .foregroundStyle(Theme.textTertiary)
                    .monospacedDigit()
            }

            CircleIconButton(systemName: "xmark", size: 40, action: close)
                .accessibilityLabel(Text("Close"))
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(wizard.step.title)
                .font(.appTitle)
                .foregroundStyle(.white)
            Text(wizard.step.subtitle)
                .font(.appSubheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if wizard.step == .summary {
                PrimaryButton(title: "Generate her", icon: "wand.and.stars", action: generate)
            } else {
                PrimaryButton(title: "Next", isEnabled: wizard.canContinue) {
                    Haptics.tap()
                    wizard.goNext()
                }
            }
        }
        .frame(maxWidth: contentMaxWidth)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background {
            LinearGradient(
                colors: [Theme.background.opacity(0), Theme.background],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
    }

    private func phaseContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                CircleIconButton(systemName: "xmark", size: 40, action: close)
                    .accessibilityLabel(Text("Close"))
            }
            .frame(maxWidth: contentMaxWidth)
            .padding(.horizontal, 20)
            .padding(.top, 8)

            content()
                .frame(maxWidth: contentMaxWidth)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .transition(.opacity)
    }

    // MARK: Actions

    private func generate() {
        guard model.authorize(.characterCreate) else {
            return
        }
        Haptics.tap()
        model.speech.stop()
        startPortraitGeneration()
    }

    private func regenerate() {
        guard model.authorize(.characterCreate) else {
            return
        }
        Haptics.tap()
        startPortraitGeneration()
    }

    private func startPortraitGeneration() {
        guard wizard.phase != .generating, wizard.phase != .finishing,
            model.authorize(.characterCreate)
        else {
            return
        }
        guard AIConsentStore.shared.request(onApprove: startPortraitGeneration) else {
            return
        }
        generationTask?.cancel()
        generationTask = Task {
            await wizard.generatePortraits(using: model)
        }
    }

    private func finish() {
        guard wizard.phase != .generating, wizard.phase != .finishing,
            model.authorize(.characterCreate)
        else {
            return
        }
        guard AIConsentStore.shared.request(onApprove: finish) else {
            return
        }
        Haptics.tap()
        generationTask?.cancel()
        generationTask = Task {
            await wizard.finishCreation(using: model)
        }
    }

    private func retry(_ failure: CreateFailure) {
        guard model.authorize(.characterCreate) else {
            return
        }
        switch failure.stage {
        case .portraits:
            startPortraitGeneration()
        case .saving:
            finish()
        }
    }

    private func backToWizard() {
        Haptics.tap()
        wizard.discardPortraits()
        wizard.step = .summary
        wizard.phase = .wizard
    }

    private func close() {
        generationTask?.cancel()
        generationTask = nil
        model.speech.stop()
        if wizard.savedCharacterID == nil {
            wizard.discardPortraits()
        }
        dismiss()
    }

    private func complete(characterID: String) {
        generationTask = nil
        Haptics.success()
        dismiss()
        model.selectedTab = .explore
        model.explorePath = [.companion(characterID)]
        model.grant(.createdCharacter)
    }
}

private struct CreateProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.surfaceHigh)
                Capsule()
                    .fill(Theme.ctaGradient)
                    .frame(width: max(8, proxy.size.width * progress))
                    .shadow(color: Theme.pink.opacity(0.5), radius: 6)
            }
        }
        .frame(height: 6)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: progress)
        .accessibilityElement()
        .accessibilityValue(Text(verbatim: "\(Int(progress * 100))%"))
    }
}
