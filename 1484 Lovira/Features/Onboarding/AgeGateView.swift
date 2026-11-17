import SwiftUI

struct AgeGateView: View {
    @Environment(AppModel.self) private var model
    @State private var isConfirmed = false
    @State private var legalDocument: WelcomeLegalDocument?

    var body: some View {
        ZStack {
            OnboardingCollage()
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "heart.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(Theme.ctaGradient)
                Text("Your AI companion who is always there for you")
                    .font(.appH3)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(
                    verbatim: LocalizedText(
                        "This app is for adults only. All characters are fictional and AI-generated.",
                        ru: "Приложение только для совершеннолетних. Все персонажи вымышлены и созданы ИИ."
                    ).value
                )
                .font(.appSubheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)

                Button {
                    Haptics.tap()
                    isConfirmed.toggle()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isConfirmed ? "checkmark.square.fill" : "square")
                            .font(.system(size: 22))
                            .foregroundStyle(isConfirmed ? Theme.pink : Theme.textSecondary)
                        Text("I am 18 years or older")
                            .font(.appBodyMedium)
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(16)
                    .background(Theme.surface.opacity(0.9), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                PrimaryButton(title: "Continue", isEnabled: isConfirmed) {
                    model.profile.hasConfirmedAge = true
                }

                HStack(spacing: 4) {
                    Text("By continuing you agree to our")
                    Button("Terms") { legalDocument = .terms }
                        .foregroundStyle(Theme.pink)
                    Text("and")
                    Button("Privacy Policy") { legalDocument = .privacy }
                        .foregroundStyle(Theme.pink)
                }
                .font(.appCaption)
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: 460)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .sheet(item: $legalDocument) { document in
            WelcomeLegalScreen(document: document)
        }
    }
}

/// Photo collage backdrop used on the first-launch screens.
struct OnboardingCollage: View {
    var photos = ["mia_01", "yuna_01", "sofia_01", "elena_01", "amara_01", "chloe_01"]

    var body: some View {
        GeometryReader { proxy in
            let columns = proxy.size.width > 700 ? 3 : 2
            let width = (proxy.size.width - CGFloat(columns + 1) * 8) / CGFloat(columns)
            ZStack(alignment: .bottom) {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(0..<columns, id: \.self) { column in
                        VStack(spacing: 8) {
                            ForEach(Array(photos.enumerated()).filter { $0.offset % columns == column }, id: \.offset) {
                                item in
                                PhotoView(source: .asset(item.element), maxPixelSize: 700)
                                    .frame(width: width, height: width * 4 / 3)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                        }
                        .offset(y: column.isMultiple(of: 2) ? -40 : 10)
                    }
                }
                .padding(.horizontal, 8)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)

                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: Theme.background.opacity(0.6), location: 0.3),
                        .init(color: Theme.background, location: 0.58),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .background(Theme.background)
    }
}
