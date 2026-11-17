import SwiftUI

/// Illustration-only scenes. Navigation, purchase state and primary controls belong to the host.
enum WelcomeSceneKind: Hashable {
    case conversation
    case companions
    case reviews
    case media
    case premium
    case scenarios
}

struct WelcomeScene: View {
    let kind: WelcomeSceneKind

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var accessibleCanvasHeight: CGFloat = 400

    var body: some View {
        GeometryReader { geometry in
            if kind == .reviews {
                WelcomeReviewExamples()
            } else if reduceMotion {
                artwork(in: geometry.size, motion: .still)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    artwork(in: geometry.size, motion: WelcomeSceneMotion(date: context.date))
                }
            }
        }
        .transition(.opacity)
    }

    private var minimumArtworkHeight: CGFloat {
        switch kind {
        case .conversation, .companions: return 260
        case .scenarios: return 180
        case .premium, .reviews, .media: return 120
        }
    }

    @ViewBuilder
    private func artwork(in size: CGSize, motion: WelcomeSceneMotion) -> some View {
        let minimumHeight = minimumArtworkHeight
        let needsAccessibilitySpace = dynamicTypeSize.isAccessibilitySize
        let contentHeight = needsAccessibilitySpace ? accessibleCanvasHeight + 16 : minimumHeight

        if kind == .media {
            // The media scene handles its own natural-height accessibility overflow.
            scene(in: size, motion: motion)
        } else if needsAccessibilitySpace || size.height < minimumHeight {
            // Only an exceptionally short slot or accessibility text requires overflow.
            // Normal compact slots shrink the collage first, not the benefit text.
            ScrollView(.vertical) {
                scene(
                    in: CGSize(width: size.width, height: max(size.height, contentHeight)),
                    motion: motion
                )
            }
        } else {
            scene(in: size, motion: motion)
        }
    }

    private func scene(in size: CGSize, motion: WelcomeSceneMotion) -> some View {
        let scale = max(0, min((size.width - 16) / 340, (size.height - 16) / 400, 1.45))
        let canvasHeight =
            dynamicTypeSize.isAccessibilitySize
            ? max(400 * scale, accessibleCanvasHeight)
            : 400 * scale

        return ZStack {
            if kind == .conversation || kind == .companions {
                bloom(opacity: motion.bloom)
                    .frame(width: 330 * scale, height: canvasHeight)
                    .accessibilityHidden(true)
            }

            switch kind {
            case .conversation:
                conversation(scale: scale, height: canvasHeight, motion: motion)
            case .companions:
                companions(scale: scale, height: canvasHeight, motion: motion)
            case .media:
                WelcomeMediaScene(float: motion.float)
                    .padding(8)
            case .premium, .scenarios:
                WelcomeCollageScene(isScenarios: kind == .scenarios, motion: motion)
                    .padding(8)
            case .reviews:
                EmptyView()
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func bloom(opacity: Double) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [Theme.pink.opacity(opacity), Theme.violet.opacity(opacity / 2), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 180
                )
            )
    }

    private func conversation(scale: CGFloat, height: CGFloat, motion: WelcomeSceneMotion)
        -> some View
    {
        ZStack(alignment: .bottom) {
            WelcomeBundledPhoto(asset: "mia_01")
                .overlay(Theme.cardFade)
                .clipShape(RoundedRectangle(cornerRadius: WelcomeDesign.cornerRadius, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8 * scale) {
                HStack(spacing: 6 * scale) {
                    Circle()
                        .fill(Theme.online)
                        .frame(width: 6 * scale, height: 6 * scale)
                    Text(verbatim: "Mia · " + LocalizedText("AI companion", ru: "ИИ-собеседница").value)
                        .font(
                            .poppins(WelcomeSceneText.size(12, scale: scale), .semibold, relativeTo: .caption)
                        )
                        .foregroundStyle(.white)
                }
                Spacer(minLength: 8 * scale)
                message(
                    LocalizedText("Rough day at work…", ru: "Тяжёлый день на работе…"),
                    isUser: true,
                    scale: scale
                )
                message(
                    LocalizedText(
                        "Come here, tell me everything 💕 I'm all yours tonight",
                        ru: "Иди сюда, расскажи всё 💕 Сегодня я только твоя"
                    ),
                    isUser: false,
                    scale: scale
                )
            }
            .padding(14 * scale)
        }
        .frame(width: 300 * scale, height: max(0, height - 32 * scale))
        .offset(y: motion.float * scale)
        .accessibilityElement(children: .combine)
    }

    private func message(_ copy: LocalizedText, isUser: Bool, scale: CGFloat) -> some View {
        HStack(spacing: 12 * scale) {
            if isUser {
                Spacer(minLength: 12 * scale)
            }
            Text(verbatim: copy.value)
                .font(.poppins(WelcomeSceneText.size(13, scale: scale), relativeTo: .subheadline))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12 * scale)
                .padding(.vertical, 8 * scale)
                .background {
                    RoundedRectangle(cornerRadius: WelcomeDesign.cornerRadius, style: .continuous)
                        .fill(isUser ? AnyShapeStyle(Theme.ctaGradient) : AnyShapeStyle(Theme.surfaceHigh))
                }
            if !isUser {
                Spacer(minLength: 12 * scale)
            }
        }
    }

    private func companions(scale: CGFloat, height: CGFloat, motion: WelcomeSceneMotion) -> some View {
        let cardHeight = max(0, (height - 36 * scale) / 2)

        return VStack(spacing: 12 * scale) {
            HStack(spacing: 12 * scale) {
                companion(WelcomeCompanion.examples[0], scale: scale, height: cardHeight)
                companion(WelcomeCompanion.examples[1], scale: scale, height: cardHeight)
            }
            HStack(spacing: 12 * scale) {
                companion(WelcomeCompanion.examples[2], scale: scale, height: cardHeight)
                companion(WelcomeCompanion.examples[3], scale: scale, height: cardHeight)
            }
        }
        .offset(y: -motion.float * scale)
    }

    private func companion(_ person: WelcomeCompanion, scale: CGFloat, height: CGFloat) -> some View {
        WelcomeBundledPhoto(asset: person.asset)
            .frame(width: 144 * scale, height: height)
            .overlay(Theme.cardFade)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 2 * scale) {
                    Text(verbatim: person.name)
                        .font(
                            .poppins(WelcomeSceneText.size(15, scale: scale), .semibold, relativeTo: .headline)
                        )
                        .foregroundStyle(.white)
                    Text(verbatim: person.trait.value)
                        .font(.poppins(WelcomeSceneText.size(12, scale: scale), relativeTo: .caption))
                        .foregroundStyle(Theme.pink)
                }
                .padding(10 * scale)
            }
            .clipShape(RoundedRectangle(cornerRadius: WelcomeDesign.cornerRadius, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: person.name + ", " + person.trait.value))
    }
}

enum WelcomeSceneText {
    static func size(_ base: CGFloat, scale: CGFloat) -> CGFloat {
        max(base, base * scale)
    }
}

/// Bundled artwork is immediately present and has no independently animated loading placeholder.
struct WelcomeBundledPhoto: View {
    let asset: String

    var body: some View {
        Color.clear
            .overlay {
                Image(asset)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
    }
}

private struct WelcomeSceneMotion {
    let float: CGFloat
    let bloom: Double

    static let still = WelcomeSceneMotion(float: 0, bloom: 0.13)

    private init(float: CGFloat, bloom: Double) {
        self.float = float
        self.bloom = bloom
    }

    init(date: Date) {
        // Absolute time keeps reused heroes in phase; no appearance tasks or delayed reveals.
        let phase = date.timeIntervalSinceReferenceDate * (.pi / 3.6)
        float = CGFloat(sin(phase)) * 2
        bloom = 0.13 + sin(phase) * 0.025
    }
}

private struct WelcomeCompanion {
    let asset: String
    let name: String
    let trait: LocalizedText

    static let examples: [WelcomeCompanion] = [
        .init(asset: "mia_01", name: "Mia", trait: LocalizedText("Caring", ru: "Заботливая")),
        .init(asset: "sofia_01", name: "Sofía", trait: LocalizedText("Passionate", ru: "Страстная")),
        .init(asset: "yuna_01", name: "Yuna", trait: LocalizedText("Shy", ru: "Застенчивая")),
        .init(asset: "amara_01", name: "Amara", trait: LocalizedText("Confident", ru: "Уверенная")),
    ]
}

private struct WelcomeCollageScene: View {
    let isScenarios: Bool
    let motion: WelcomeSceneMotion

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var benefitFontSize: CGFloat = 12

    var body: some View {
        VStack(spacing: 8) {
            if isScenarios {
                scenarioAccess
                    .layoutPriority(1)
            }

            Image(isScenarios ? "ScenariosCollage" : "MainCollage")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 600, maxHeight: 400)
                .offset(y: motion.float)
                .accessibilityHidden(true)

            benefits
                .frame(maxWidth: 520)
                .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            Text(
                verbatim: LocalizedText(
                    isScenarios ? "Roleplay scenarios" : "Premium features",
                    ru: isScenarios ? "Ролевые сценарии" : "Возможности Premium"
                ).value))
    }

    private var scenarioAccess: some View {
        VStack(spacing: 4) {
            Text(
                verbatim: LocalizedText(
                    "Unlock every roleplay scenario", ru: "Откройте все ролевые сценарии"
                ).value
            )
            .font(.headline)
            .foregroundStyle(.white)
            .accessibilityAddTraits(.isHeader)
            Text(
                verbatim: LocalizedText(
                    "A separate AI subscription unlocks every story to play out in chat with your chosen companion",
                    ru: "Отдельная AI-подписка открывает все истории для ролевого чата с выбранной девушкой"
                ).value
            )
            .font(.caption)
            .foregroundStyle(Theme.textSecondary)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: 520)
        .accessibilityIdentifier("paywall.scenarios.benefit")
    }

    @ViewBuilder
    private var benefits: some View {
        if isScenarios {
            LazyVGrid(columns: columns(count: 3), spacing: 8) {
                benefit("cup.and.saucer", copy: LocalizedText("Café date", ru: "Свидание в кафе"))
                benefit("flame", copy: LocalizedText("Cozy evening", ru: "Вечер у камина"))
                benefit("tram", copy: LocalizedText("Night train", ru: "Ночной поезд"))
            }
        } else {
            LazyVGrid(columns: columns(count: 2), spacing: 8) {
                benefit(
                    "bubble.left.and.bubble.right",
                    copy: LocalizedText("Chats · faster replies", ru: "Чат · быстрые ответы")
                )
                benefit(
                    "person.crop.rectangle.badge.plus",
                    copy: LocalizedText("Catalog · create & edit", ru: "Каталог · свой персонаж"),
                    details: LocalizedText(
                        "Companion catalog, character creation and editing. First creation is free for life; edits are paid.",
                        ru:
                            "Каталог, создание и редактирование. Первое создание бесплатно навсегда; правки платные."
                    )
                )
                benefit(
                    "waveform",
                    copy: LocalizedText("Voice · chat photos", ru: "Голос · фото в чате"),
                    details: LocalizedText(
                        "Voice messages and photos in chat", ru: "Голосовые сообщения и фото в чате")
                )
                benefit("photo.on.rectangle", copy: LocalizedText("Gallery", ru: "Галерея"))
            }
        }
    }

    private func columns(count: Int) -> [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 8),
            count: dynamicTypeSize.isAccessibilitySize ? 1 : count
        )
    }

    private func benefit(_ symbol: String, copy: LocalizedText, details: LocalizedText? = nil)
        -> some View
    {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(Theme.pink)
                .frame(width: 20)
                .accessibilityHidden(true)
            Text(verbatim: copy.value)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.system(size: benefitFontSize, weight: .medium))
        .frame(height: dynamicTypeSize.isAccessibilitySize ? nil : benefitFontSize * 2.5)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: WelcomeDesign.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: WelcomeDesign.cornerRadius)
                .strokeBorder(Theme.stroke, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: (details ?? copy).value))
    }
}
