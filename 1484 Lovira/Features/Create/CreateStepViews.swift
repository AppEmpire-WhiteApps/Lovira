import SwiftUI

/// Content of the current wizard step.
struct CreateStepContent: View {
    @Bindable var wizard: CreateWizardModel
    var editingCharacter: CustomCharacter? = nil

    var body: some View {
        switch wizard.step {
        case .ethnicity:
            CreateEthnicityStep(wizard: wizard)
        case .age:
            CreateAgeStep(wizard: wizard)
        case .eyes:
            CreateEyesStep(wizard: wizard)
        case .hair:
            CreateHairStep(wizard: wizard)
        case .body:
            CreateBodyStep(wizard: wizard)
        case .personality:
            CreatePersonalityStep(wizard: wizard)
        case .relationship:
            CreateRelationshipStep(wizard: wizard)
        case .interests:
            CreateInterestsStep(wizard: wizard)
        case .voice:
            CreateVoiceStep(wizard: wizard)
        case .name:
            CreateNameStep(wizard: wizard)
        case .summary:
            CreateSummaryStep(wizard: wizard, editingCharacter: editingCharacter)
        }
    }
}

// MARK: - Shared pieces

private let createCardRadius: CGFloat = 18

private struct CreateCheckmark: View {
    var body: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(Theme.ctaGradient, in: Circle())
    }
}

private struct CreateSelectableCard: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .background(
                isSelected ? Theme.pinkBackground : Theme.surface,
                in: RoundedRectangle(cornerRadius: createCardRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: createCardRadius, style: .continuous)
                    .strokeBorder(isSelected ? Theme.pink : Theme.stroke, lineWidth: isSelected ? 2 : 1)
            }
    }
}

private extension View {
    func createSelectable(_ isSelected: Bool) -> some View {
        modifier(CreateSelectableCard(isSelected: isSelected))
    }
}

private struct CreateSectionLabel: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack {
            Text(title)
                .font(.appCallout)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.appCaptionBold)
                    .foregroundStyle(Theme.pink)
            }
        }
    }
}

/// Wrapping layout for chips.
struct CreateFlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews: subviews, maxWidth: proposal.width ?? .infinity)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(subviews: subviews, maxWidth: bounds.width)
        for row in rows {
            for item in row.items {
                let point = CGPoint(x: bounds.minX + item.x, y: bounds.minY + row.y)
                subviews[item.index].place(at: point, proposal: ProposedViewSize(item.size))
            }
        }
    }

    private struct Item {
        let index: Int
        let x: CGFloat
        let size: CGSize
    }

    private struct Row {
        var y: CGFloat
        var height: CGFloat = 0
        var width: CGFloat = 0
        var items: [Item] = []
    }

    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row(y: 0)
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let x = current.items.isEmpty ? 0 : current.width + spacing
            if !current.items.isEmpty && x + size.width > maxWidth {
                let nextY = current.y + current.height + spacing
                rows.append(current)
                current = Row(y: nextY)
                current.items.append(Item(index: index, x: 0, size: size))
                current.width = size.width
                current.height = size.height
            } else {
                current.items.append(Item(index: index, x: x, size: size))
                current.width = x + size.width
                current.height = max(current.height, size.height)
            }
        }
        if !current.items.isEmpty {
            rows.append(current)
        }
        return rows
    }
}

// MARK: - 1. Ethnicity

private struct CreateEthnicityStep: View {
    @Bindable var wizard: CreateWizardModel

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Ethnicity.allCases) { ethnicity in
                card(ethnicity)
            }
        }
    }

    private func card(_ ethnicity: Ethnicity) -> some View {
        let isSelected = wizard.ethnicity == ethnicity
        return Button {
            Haptics.tap()
            wizard.ethnicity = ethnicity
        } label: {
            PhotoView(source: .asset(ethnicity.exampleAsset), maxPixelSize: 600)
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .overlay {
                    Theme.cardFade
                }
                .overlay(alignment: .bottomLeading) {
                    Text(ethnicity.title)
                        .font(.appBodyMedium)
                        .foregroundStyle(.white)
                        .padding(12)
                }
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        CreateCheckmark()
                            .padding(10)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: createCardRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: createCardRadius, style: .continuous)
                        .strokeBorder(isSelected ? Theme.pink : Theme.stroke, lineWidth: isSelected ? 3 : 1)
                }
                .shadow(color: isSelected ? Theme.pink.opacity(0.35) : .clear, radius: 12, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - 2. Age

private struct CreateAgeStep: View {
    @Bindable var wizard: CreateWizardModel

    private struct AgePreset: Hashable {
        let label: String
        let age: Double
    }

    private let presets = [
        AgePreset(label: "21–25", age: 23),
        AgePreset(label: "26–30", age: 28),
        AgePreset(label: "31–40", age: 35),
        AgePreset(label: "40+", age: 42)
    ]

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 2) {
                Text(verbatim: "\(wizard.ageValue)")
                    .font(.poppins(88, .bold))
                    .foregroundStyle(Theme.ctaGradient)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: wizard.ageValue)
                Text("years old")
                    .font(.appBody)
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .cardBackground()

            VStack(spacing: 8) {
                Slider(value: $wizard.age, in: 21...45, step: 1)
                    .tint(Theme.pink)
                    .onChange(of: wizard.ageValue) { _, _ in
                        Haptics.tap()
                    }
                HStack {
                    Text(verbatim: "21")
                    Spacer()
                    Text(verbatim: "45")
                }
                .font(.appCaption)
                .foregroundStyle(Theme.textTertiary)
            }

            HStack(spacing: 10) {
                ForEach(presets, id: \.self) { preset in
                    let isSelected = rangeContains(preset.label)
                    Button {
                        withAnimation(.snappy) {
                            wizard.age = preset.age
                        }
                    } label: {
                        ChipView(title: preset.label, isSelected: isSelected)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }

    private func rangeContains(_ label: String) -> Bool {
        let age = wizard.ageValue
        switch label {
        case "21–25": return (21...25).contains(age)
        case "26–30": return (26...30).contains(age)
        case "31–40": return (31...40).contains(age)
        default: return age > 40
        }
    }
}

// MARK: - 3. Eyes

private struct CreateEyeSwatch: View {
    let color: Color
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.92))
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.75), color, Color.black.opacity(0.55)],
                        center: .center,
                        startRadius: size * 0.08,
                        endRadius: size * 0.36
                    )
                )
                .frame(width: size * 0.7, height: size * 0.7)
            Circle()
                .fill(Color.black)
                .frame(width: size * 0.24, height: size * 0.24)
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: size * 0.1, height: size * 0.1)
                .offset(x: size * 0.1, y: -size * 0.1)
        }
        .frame(width: size, height: size)
    }
}

private struct CreateEyesStep: View {
    @Bindable var wizard: CreateWizardModel

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(EyeColor.allCases) { eye in
                let isSelected = wizard.eyeColor == eye
                Button {
                    Haptics.tap()
                    wizard.eyeColor = eye
                } label: {
                    VStack(spacing: 10) {
                        CreateEyeSwatch(color: Color(hex: eye.swatch))
                            .overlay {
                                Circle()
                                    .strokeBorder(isSelected ? Theme.pink : .clear, lineWidth: 3)
                                    .padding(-5)
                            }
                        Text(eye.title)
                            .font(.appCallout)
                            .foregroundStyle(isSelected ? .white : Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .createSelectable(isSelected)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

// MARK: - 4. Hair

private struct CreateHairStep: View {
    @Bindable var wizard: CreateWizardModel

    private let columns = [GridItem(.adaptive(minimum: 92), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                CreateSectionLabel(title: LocalizedText("Hairstyle", ru: "Причёска").value)
                CreateFlowLayout(spacing: 10) {
                    ForEach(HairStyle.allCases) { style in
                        Button {
                            Haptics.tap()
                            wizard.hairStyle = style
                        } label: {
                            ChipView(title: style.title, isSelected: wizard.hairStyle == style)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                CreateSectionLabel(title: LocalizedText("Hair color", ru: "Цвет волос").value)
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(HairColor.allCases) { color in
                        swatch(color)
                    }
                }
            }
        }
    }

    private func swatch(_ hair: HairColor) -> some View {
        let isSelected = wizard.hairColor == hair
        let base = Color(hex: hair.swatch)
        return Button {
            Haptics.tap()
            wizard.hairColor = hair
        } label: {
            VStack(spacing: 8) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [base.opacity(0.75), base, base.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay {
                        Circle()
                            .strokeBorder(isSelected ? Theme.pink : Color.white.opacity(0.12), lineWidth: isSelected ? 3 : 1)
                            .padding(isSelected ? -4 : 0)
                    }
                Text(hair.title)
                    .font(.appCaption)
                    .foregroundStyle(isSelected ? .white : Theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .createSelectable(isSelected)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - 5. Body

private struct CreateBodyStep: View {
    @Bindable var wizard: CreateWizardModel

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(BodyType.allCases) { bodyType in
                let isSelected = wizard.bodyType == bodyType
                Button {
                    Haptics.tap()
                    wizard.bodyType = bodyType
                } label: {
                    VStack(spacing: 14) {
                        Image(systemName: bodyType.icon)
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(isSelected ? AnyShapeStyle(Theme.ctaGradient) : AnyShapeStyle(Theme.textSecondary))
                            .frame(height: 48)
                        Text(bodyType.title)
                            .font(.appBodyMedium)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .createSelectable(isSelected)
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            CreateCheckmark()
                                .padding(10)
                        }
                    }
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

// MARK: - 6. Personality

private struct CreatePersonalityStep: View {
    @Bindable var wizard: CreateWizardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CreateSectionLabel(
                title: LocalizedText("Traits", ru: "Черты").value,
                trailing: "\(wizard.traits.count)/\(CreateWizardModel.maxTraits)"
            )
            CreateFlowLayout(spacing: 10) {
                ForEach(CompanionTrait.allCases) { trait in
                    let isSelected = wizard.traits.contains(trait)
                    let isFull = wizard.traits.count >= CreateWizardModel.maxTraits
                    Button {
                        Haptics.tap()
                        wizard.toggle(trait)
                    } label: {
                        ChipView(title: trait.title, icon: trait.icon, isSelected: isSelected)
                            .opacity(isFull && !isSelected ? 0.45 : 1)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }

            if let trait = wizard.traits.last {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: trait.icon)
                        .foregroundStyle(Theme.pink)
                    Text(trait.subtitle)
                        .font(.appSubheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardBackground(cornerRadius: 16)
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - 7. Relationship

private struct CreateRelationshipStep: View {
    @Bindable var wizard: CreateWizardModel

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Relationship.allCases) { relationship in
                let isSelected = wizard.relationship == relationship
                Button {
                    Haptics.tap()
                    wizard.relationship = relationship
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: relationship.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                isSelected ? AnyShapeStyle(Theme.ctaGradient) : AnyShapeStyle(Theme.surfaceHigh),
                                in: Circle()
                            )
                        Text(relationship.title)
                            .font(.appBodyMedium)
                            .foregroundStyle(.white)
                        Spacer()
                        if isSelected {
                            CreateCheckmark()
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .createSelectable(isSelected)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

// MARK: - 8. Interests

private struct CreateInterestsStep: View {
    @Bindable var wizard: CreateWizardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CreateSectionLabel(
                title: LocalizedText("Hobbies", ru: "Увлечения").value,
                trailing: "\(wizard.interests.count)/\(CreateWizardModel.maxInterests)"
            )
            CreateFlowLayout(spacing: 10) {
                ForEach(Interest.allCases) { interest in
                    let isSelected = wizard.interests.contains(interest)
                    let isFull = wizard.interests.count >= CreateWizardModel.maxInterests
                    Button {
                        Haptics.tap()
                        wizard.toggle(interest)
                    } label: {
                        ChipView(title: "\(interest.emoji) \(interest.title)", isSelected: isSelected)
                            .opacity(isFull && !isSelected ? 0.45 : 1)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }
}

// MARK: - 9. Voice

private struct CreateVoiceStep: View {
    @Environment(AppModel.self) private var model
    @Bindable var wizard: CreateWizardModel

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(VoiceStyle.allCases.enumerated()), id: \.element) { index, style in
                row(style, previewID: Self.previewID(index))
            }
        }
        .onDisappear {
            model.speech.stop()
        }
    }

    private static func previewID(_ index: Int) -> UUID {
        UUID(uuidString: String(format: "5A1C0DE0-0000-4000-8000-%012ld", index)) ?? UUID()
    }

    private func row(_ style: VoiceStyle, previewID: UUID) -> some View {
        let isSelected = wizard.voice == style
        let isPlaying = model.speech.speakingID == previewID
        return HStack(spacing: 14) {
            Button {
                guard model.authorize(.voice) else {
                    return
                }
                Haptics.tap()
                model.speech.toggle(text: style.sample, style: style, id: previewID)
            } label: {
                ZStack {
                    if isPlaying && model.speech.isPreparing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    isPlaying ? AnyShapeStyle(Theme.ctaGradient) : AnyShapeStyle(Theme.surfaceHigh),
                    in: Circle()
                )
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel(Text("Play sample"))

            Button {
                Haptics.tap()
                wizard.voice = style
            } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(style.title)
                            .font(.appBodyMedium)
                            .foregroundStyle(.white)
                        Text(style.subtitle)
                            .font(.appCaption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer(minLength: 8)
                    if isSelected {
                        CreateCheckmark()
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .createSelectable(isSelected)
    }
}

// MARK: - 10. Name

private struct CreateNameStep: View {
    @Bindable var wizard: CreateWizardModel
    @FocusState private var isFocused: Bool

    private let suggestions = Array(CreateWizardModel.randomNames.prefix(8))

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                TextField("", text: $wizard.name, prompt: Text("Her name").foregroundStyle(Theme.textTertiary))
                    .font(.appH3)
                    .foregroundStyle(.white)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($isFocused)
                    .onSubmit {
                        wizard.goNext()
                    }
                    .onChange(of: wizard.name) { _, _ in
                        wizard.limitNameLength()
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 60)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: createCardRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: createCardRadius, style: .continuous)
                            .strokeBorder(isFocused ? Theme.pink : Theme.stroke, lineWidth: isFocused ? 2 : 1)
                    }

                Button {
                    Haptics.tap()
                    withAnimation(.snappy) {
                        wizard.randomizeName()
                    }
                } label: {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(Theme.ctaGradient, in: RoundedRectangle(cornerRadius: createCardRadius, style: .continuous))
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(Text("Random name"))
            }

            CreateSectionLabel(title: LocalizedText("Popular names", ru: "Популярные имена").value)
            CreateFlowLayout(spacing: 10) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        Haptics.tap()
                        wizard.name = suggestion
                    } label: {
                        ChipView(title: suggestion, isSelected: wizard.trimmedName == suggestion)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
        .onAppear {
            isFocused = wizard.trimmedName.isEmpty
        }
    }
}

// MARK: - 11. Summary

private struct CreateSummaryStep: View {
    @Bindable var wizard: CreateWizardModel
    var editingCharacter: CustomCharacter? = nil

    var body: some View {
        VStack(spacing: 16) {
            hero

            VStack(spacing: 0) {
                if editingCharacter != nil {
                    row(.name, value: wizard.trimmedName)
                }
                row(.ethnicity, value: wizard.ethnicity?.title ?? "—")
                row(.age, value: "\(wizard.ageValue)")
                row(.eyes, value: wizard.eyeColor.title)
                row(.hair, value: "\(wizard.hairStyle.title), \(wizard.hairColor.title.lowercased())")
                row(.body, value: wizard.bodyType.title)
                row(.personality, value: wizard.traits.map(\.title).joined(separator: ", "))
                row(.relationship, value: wizard.relationship.title)
                row(.interests, value: wizard.interests.map(\.emoji).joined(separator: " "))
                row(.voice, value: wizard.voice.title, isLast: true)
            }
            .cardBackground()
        }
    }

    private var hero: some View {
        ZStack {
            PhotoView(
                source: editingCharacter.map { .file($0.avatarFile) }
                    ?? .asset((wizard.ethnicity ?? .caucasian).exampleAsset),
                maxPixelSize: 500
            )
            .blur(radius: 22)
            .overlay {
                Color.black.opacity(0.35)
            }

            VStack(spacing: 8) {
                Image(systemName: editingCharacter == nil ? "wand.and.stars" : "pencil")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(Theme.premiumGradient, in: Circle())
                    .shadow(color: Theme.violet.opacity(0.5), radius: 14)
                Text(verbatim: "\(wizard.trimmedName), \(wizard.ageValue)")
                    .font(.appH2)
                    .foregroundStyle(.white)
                Text(summaryMessage)
                    .font(.appCaption)
                    .foregroundStyle(Color.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        }
    }

    private var summaryMessage: String {
        if editingCharacter != nil {
            return LocalizedText(
                "Existing photos stay unchanged. Your new look applies to future generations.",
                ru: "Текущие фото не изменятся. Новая внешность будет использована в будущих генерациях."
            ).value
        }
        return LocalizedText(
            "Her photorealistic portrait will be created by AI",
            ru: "Её фотореалистичный портрет создаст ИИ"
        ).value
    }

    private func row(_ step: CreateStep, value: String, isLast: Bool = false) -> some View {
        Button {
            Haptics.tap()
            wizard.jump(to: step)
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Text(step.title)
                        .font(.appSubheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                    Spacer(minLength: 12)
                    Text(value)
                        .font(.appCallout)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.pink)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                if !isLast {
                    Rectangle()
                        .fill(Theme.stroke)
                        .frame(height: 0.5)
                        .padding(.leading, 16)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
