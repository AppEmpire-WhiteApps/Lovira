import Foundation

enum WelcomePage: Int, CaseIterable {
    case conversation
    case companions
    case reviews
    case media

    var scene: WelcomeSceneKind {
        switch self {
        case .conversation: .conversation
        case .companions: .companions
        case .reviews: .reviews
        case .media: .media
        }
    }

    var title: String {
        switch self {
        case .conversation:
            LocalizedText("She Understands\nYour World", ru: "Она Понимает\nТвой Мир").value
        case .companions:
            LocalizedText("Your Type\nYour Connection", ru: "Твой Типаж\nТвоя История").value
        case .reviews:
            LocalizedText("We Value\nYour Feedback", ru: "Мы Ценим\nВаш Отзыв").value
        case .media:
            LocalizedText("Share Photos\nand Voice Messages", ru: "Делись Фото\nи Голосовыми").value
        }
    }

    var subtitle: String {
        switch self {
        case .conversation:
            LocalizedText(
                "Share your day with an AI companion\nwho listens and remembers",
                ru: "Расскажи о своём дне ИИ-подруге,\nкоторая слушает и помнит"
            ).value
        case .companions:
            LocalizedText(
                "Meet someone who fits your mood\nor create your own companion",
                ru: "Найди девушку под настроение\nили создай свою ИИ-подругу"
            ).value
        case .reviews:
            LocalizedText(
                "Any feedback is important to us\nso that we could improve our app",
                ru: "Нам важен каждый отзыв,\nчтобы делать приложение лучше"
            ).value
        case .media:
            LocalizedText(
                "Exchange photos and voice messages\nwith your AI companion in chat",
                ru: "Обменивайся фото и голосовыми\nс ИИ-подругой прямо в чате"
            ).value
        }
    }

    var message: String {
        switch self {
        case .conversation:
            LocalizedText("A conversation that remembers you", ru: "Разговор, в котором тебя помнят")
                .value
        case .companions:
            LocalizedText("Her look, voice and personality", ru: "Её внешность, голос и характер").value
        case .reviews:
            LocalizedText("Check why users love it", ru: "Узнайте, за что его любят").value
        case .media:
            LocalizedText("More ways to connect", ru: "Больше способов общаться").value
        }
    }
}
