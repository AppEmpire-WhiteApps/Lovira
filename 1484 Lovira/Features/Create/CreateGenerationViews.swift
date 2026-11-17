import SwiftUI

// MARK: - Generating

struct CreateGeneratingView: View {
    let title: String
    let statuses: [String]
    let placeholderCount: Int

    @State private var statusIndex = 0
    @State private var isPulsing = false

    static var portraitStatuses: [String] {
        [
            LocalizedText("Sketching her features…", ru: "Рисуем черты лица…").value,
            LocalizedText("Choosing the perfect light…", ru: "Подбираем идеальный свет…").value,
            LocalizedText("Adding natural details…", ru: "Добавляем живые детали…").value,
            LocalizedText("Styling her hair…", ru: "Укладываем волосы…").value,
            LocalizedText("Almost there, she's getting ready…", ru: "Почти всё, она собирается…").value
        ]
    }

    static var finishingStatuses: [String] {
        [
            LocalizedText("Taking a few more photos…", ru: "Делаем ещё пару фото…").value,
            LocalizedText("Filling her gallery…", ru: "Заполняем её галерею…").value,
            LocalizedText("Teaching her your name…", ru: "Она запоминает твоё имя…").value
        ]
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 12)
            orb

            VStack(spacing: 10) {
                Text(title)
                    .font(.appH2)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(statuses.isEmpty ? "" : statuses[statusIndex % statuses.count])
                    .font(.appSubheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .id(statusIndex)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                Text("This usually takes up to a minute")
                    .font(.appCaption)
                    .foregroundStyle(Theme.textTertiary)
            }

            if placeholderCount > 0 {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<placeholderCount, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Theme.surfaceHigh)
                            .aspectRatio(3.0 / 4.0, contentMode: .fit)
                            .shimmering()
                    }
                }
                .frame(maxWidth: 360)
            }
            Spacer(minLength: 12)
        }
        .task {
            isPulsing = true
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_400_000_000)
                withAnimation(.easeInOut(duration: 0.4)) {
                    statusIndex += 1
                }
            }
        }
    }

    private var orb: some View {
        ZStack {
            Circle()
                .fill(Theme.premiumGradient)
                .frame(width: 150, height: 150)
                .blur(radius: 40)
                .opacity(isPulsing ? 0.9 : 0.4)
                .scaleEffect(isPulsing ? 1.15 : 0.85)
            Circle()
                .fill(Theme.ctaGradient)
                .frame(width: 96, height: 96)
                .scaleEffect(isPulsing ? 1.05 : 0.95)
                .shadow(color: Theme.pink.opacity(0.6), radius: 20)
            Image(systemName: "wand.and.stars")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.white)
                .symbolEffect(.pulse, options: .repeating)
        }
        .frame(height: 170)
        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: isPulsing)
    }
}

// MARK: - Pick a portrait

struct CreatePickPortraitView: View {
    @Bindable var wizard: CreateWizardModel
    let onConfirm: () -> Void
    let onRegenerate: () -> Void

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 6) {
                        Text("Meet her")
                            .font(.appTitle)
                            .foregroundStyle(.white)
                        Text("Choose the portrait you like the most")
                            .font(.appSubheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(wizard.portraits, id: \.self) { file in
                            portrait(file)
                        }
                    }
                }
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)

            VStack(spacing: 10) {
                PrimaryButton(
                    title: LocalizedStringKey(
                        LocalizedText("Choose \(wizard.trimmedName)", ru: "Выбрать \(wizard.trimmedName)").value
                    ),
                    icon: "heart.fill",
                    isEnabled: wizard.selectedPortrait != nil,
                    action: onConfirm
                )
                Button(action: onRegenerate) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("More options")
                    }
                    .font(.poppins(15, .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Theme.surfaceHigh, in: Capsule())
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.vertical, 12)
        }
    }

    private func portrait(_ file: String) -> some View {
        let isSelected = wizard.selectedPortrait == file
        return Button {
            Haptics.tap()
            wizard.selectedPortrait = file
        } label: {
            PhotoView(source: .file(file), maxPixelSize: 900)
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(isSelected ? Theme.pink : Theme.stroke, lineWidth: isSelected ? 3 : 1)
                }
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(Theme.ctaGradient, in: Circle())
                            .padding(10)
                    }
                }
                .scaleEffect(isSelected ? 1 : 0.97)
                .shadow(color: isSelected ? Theme.pink.opacity(0.4) : .clear, radius: 14, y: 4)
                .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Error

struct CreateErrorView: View {
    let message: String
    let onRetry: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.pinkBackground)
                    .frame(width: 110, height: 110)
                Circle()
                    .strokeBorder(Theme.pink.opacity(0.35), lineWidth: 1)
                    .frame(width: 136, height: 136)
                Image(systemName: "wand.and.stars.inverse")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(Theme.ctaGradient)
            }

            VStack(spacing: 10) {
                Text("She's not ready yet")
                    .font(.appH2)
                    .foregroundStyle(.white)
                Text(message)
                    .font(.appSubheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                Text("All your choices are saved.")
                    .font(.appCaption)
                    .foregroundStyle(Theme.textTertiary)
            }
            .padding(.horizontal, 12)

            Spacer()

            VStack(spacing: 10) {
                PrimaryButton(title: "Try again", icon: "arrow.clockwise", action: onRetry)
                SecondaryButton(title: "Back", icon: "chevron.left", action: onBack)
            }
            .padding(.bottom, 16)
        }
    }
}
