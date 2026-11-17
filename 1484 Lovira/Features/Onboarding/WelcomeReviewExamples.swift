import SwiftUI

/// These are deliberately fictional design previews, never customer testimonials.
struct WelcomeReviewExamples: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var headerSize: CGFloat = 12
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 13
    @ScaledMetric(relativeTo: .headline) private var awardSize: CGFloat = 18

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView(.vertical) {
                    cards
                }
            } else {
                ViewThatFits(in: .vertical) {
                    cards
                    // Also contain overflow if a host supplies less than the review stack needs.
                    ScrollView(.vertical) {
                        cards
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var cards: some View {
        VStack(alignment: .leading, spacing: 6) {
            awardHeader
            Text(
                verbatim: LocalizedText(
                    "Illustrative reviews · not customer ratings",
                    ru: "Примеры отзывов · не реальные оценки"
                ).value
            )
            .font(.system(size: headerSize, weight: .semibold))
            .foregroundStyle(Theme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)

            ForEach(WelcomeReviewExample.examples) { example in
                card(example)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    private var awardHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "laurel.leading")
                .font(.system(size: awardSize * 2.4))
                .foregroundStyle(Theme.pink)
                .accessibilityHidden(true)
            VStack(spacing: 3) {
                HStack(alignment: .center, spacing: 4) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: "star.fill")
                            .font(.system(size: awardSize * (index == 2 ? 1 : 0.65)))
                    }
                }
                .foregroundStyle(Theme.gold)
                .accessibilityHidden(true)
                Text(
                    verbatim: LocalizedText(
                        "The Highest\nUser Choice",
                        ru: "Лучший Выбор\nПользователей"
                    ).value
                )
                .font(.poppins(18, .semibold, relativeTo: .headline))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            }
            .frame(maxWidth: .infinity)
            Image(systemName: "laurel.trailing")
                .font(.system(size: awardSize * 2.4))
                .foregroundStyle(Theme.pink)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 12)
    }

    private func card(_ example: WelcomeReviewExample) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                WelcomeBundledPhoto(asset: example.avatar)
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: WelcomeDesign.cornerRadius))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: example.name.value)
                        .font(.poppins(15, .semibold, relativeTo: .subheadline))
                        .fixedSize(horizontal: false, vertical: true)
                    decorativeStars
                }
                Spacer(minLength: 0)
            }

            Text(verbatim: example.body.value)
                .font(.system(size: bodySize))
                .italic()
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: WelcomeDesign.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: WelcomeDesign.cornerRadius)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(
            Text(
                verbatim: LocalizedText(
                    "Fictional review with decorative example stars, not a customer rating",
                    ru: "Вымышленный отзыв и декоративные звёзды, не оценка пользователя"
                ).value))
    }

    private var decorativeStars: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { _ in
                Image(systemName: "star.fill")
            }
        }
        .font(.system(size: headerSize * 0.85))
        .foregroundStyle(Theme.gold)
        .accessibilityHidden(true)
    }
}

private struct WelcomeReviewExample: Identifiable {
    let id: Int
    let avatar: String
    let name: LocalizedText
    let body: LocalizedText

    static let examples: [WelcomeReviewExample] = [
        .init(
            id: 0,
            avatar: "mia_01",
            name: LocalizedText("Alex", ru: "Алекс"),
            body: LocalizedText(
                "A quick chat after work helps me unwind. She remembers what we talked about.",
                ru: "После работы приятно поболтать. Она помнит, о чём мы говорили раньше."
            )
        ),
        .init(
            id: 1,
            avatar: "yuna_01",
            name: LocalizedText("Sam", ru: "Сэм"),
            body: LocalizedText(
                "Voice replies feel warmer, and a photo gives us something new to talk about.",
                ru: "Голосовые делают беседу теплее, а фото дают новую тему для разговора."
            )
        ),
    ]
}

#if DEBUG
    #Preview("Review examples · 327 × 308") {
        WelcomeScene(kind: .reviews)
            .frame(width: 327, height: 308)
            .background(Theme.background)
    }

    #Preview("Review examples · 520 × 285") {
        WelcomeScene(kind: .reviews)
            .frame(width: 520, height: 285)
            .background(Theme.background)
    }

    #Preview("Premium · 327 × 217") {
        WelcomeScene(kind: .premium)
            .frame(width: 327, height: 217)
            .background(Theme.background)
    }
#endif
