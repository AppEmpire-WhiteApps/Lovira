import Foundation

enum CompanionTrait: String, CaseIterable, Codable, Identifiable {
    case caring
    case playful
    case shy
    case confident
    case witty
    case mysterious
    case adventurous
    case intellectual
    case romantic
    case passionate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .caring: LocalizedText("Caring", ru: "Заботливая").value
        case .playful: LocalizedText("Playful", ru: "Игривая").value
        case .shy: LocalizedText("Shy", ru: "Застенчивая").value
        case .confident: LocalizedText("Confident", ru: "Уверенная").value
        case .witty: LocalizedText("Witty", ru: "Остроумная").value
        case .mysterious: LocalizedText("Mysterious", ru: "Загадочная").value
        case .adventurous: LocalizedText("Adventurous", ru: "Авантюрная").value
        case .intellectual: LocalizedText("Intellectual", ru: "Интеллектуалка").value
        case .romantic: LocalizedText("Romantic", ru: "Романтичная").value
        case .passionate: LocalizedText("Passionate", ru: "Страстная").value
        }
    }

    var icon: String {
        switch self {
        case .caring: "heart.circle.fill"
        case .playful: "face.smiling.inverse"
        case .shy: "cloud.fill"
        case .confident: "bolt.fill"
        case .witty: "sparkles"
        case .mysterious: "moon.stars.fill"
        case .adventurous: "airplane"
        case .intellectual: "book.fill"
        case .romantic: "heart.fill"
        case .passionate: "flame.fill"
        }
    }

    /// User-facing explanations; generation prompts below stay language-independent.
    var subtitle: String {
        switch self {
        case .caring:
            LocalizedText("Warm, caring and supportive", ru: "Тёплая, заботливая и поддерживающая").value
        case .playful:
            LocalizedText("Loves jokes, teasing and light flirting", ru: "Любит шутки, поддразнивания и лёгкий флирт").value
        case .shy:
            LocalizedText("Sweet and a little shy, opens up slowly", ru: "Милая и немного застенчивая, раскрывается постепенно").value
        case .confident:
            LocalizedText("Direct and confident, knows what she wants", ru: "Прямая и уверенная, знает, чего хочет").value
        case .witty:
            LocalizedText("Quick-witted with a charming sense of humor", ru: "Находчивая, с обаятельным чувством юмора").value
        case .mysterious:
            LocalizedText("Intriguing, with a hint of mystery", ru: "Интригующая, с ноткой загадочности").value
        case .adventurous:
            LocalizedText("Spontaneous and always ready for an adventure", ru: "Спонтанная и всегда готовая к приключениям").value
        case .intellectual:
            LocalizedText("Curious and thoughtful, enjoys deep conversations", ru: "Любознательная и вдумчивая, любит глубокие разговоры").value
        case .romantic:
            LocalizedText("Tender, loves sweet words and dreaming together", ru: "Нежная, любит тёплые слова и совместные мечты").value
        case .passionate:
            LocalizedText("Expressive, with strong and vivid emotions", ru: "Экспрессивная, с сильными и яркими эмоциями").value
        }
    }

    var promptDescription: String {
        switch self {
        case .caring: "warm, caring and supportive, notices how the user feels"
        case .playful: "playful and teasing, loves jokes and light flirting"
        case .shy: "a little shy and sweet, opens up slowly, cute reactions"
        case .confident: "confident and direct, knows what she wants"
        case .witty: "witty and sarcastic in a charming way, quick comebacks"
        case .mysterious: "mysterious and intriguing, answers with a hint of secrecy"
        case .adventurous: "adventurous and spontaneous, suggests fun ideas"
        case .intellectual: "smart and curious, enjoys deep conversations"
        case .romantic: "romantic and tender, loves sweet words and dreaming together"
        case .passionate: "passionate and expressive, emotions are strong and vivid"
        }
    }
}

enum Interest: String, CaseIterable, Codable, Identifiable {
    case travel
    case yoga
    case gaming
    case movies
    case cooking
    case music
    case fashion
    case books
    case fitness
    case art
    case dancing
    case photography
    case nature
    case coffee

    var id: String { rawValue }

    var title: String {
        switch self {
        case .travel: LocalizedText("Travel", ru: "Путешествия").value
        case .yoga: LocalizedText("Yoga", ru: "Йога").value
        case .gaming: LocalizedText("Gaming", ru: "Игры").value
        case .movies: LocalizedText("Movies", ru: "Кино").value
        case .cooking: LocalizedText("Cooking", ru: "Кулинария").value
        case .music: LocalizedText("Music", ru: "Музыка").value
        case .fashion: LocalizedText("Fashion", ru: "Мода").value
        case .books: LocalizedText("Books", ru: "Книги").value
        case .fitness: LocalizedText("Fitness", ru: "Фитнес").value
        case .art: LocalizedText("Art", ru: "Искусство").value
        case .dancing: LocalizedText("Dancing", ru: "Танцы").value
        case .photography: LocalizedText("Photography", ru: "Фотография").value
        case .nature: LocalizedText("Nature", ru: "Природа").value
        case .coffee: LocalizedText("Coffee", ru: "Кофе").value
        }
    }

    var emoji: String {
        switch self {
        case .travel: "✈️"
        case .yoga: "🧘‍♀️"
        case .gaming: "🎮"
        case .movies: "🎬"
        case .cooking: "🍝"
        case .music: "🎧"
        case .fashion: "👗"
        case .books: "📚"
        case .fitness: "💪"
        case .art: "🎨"
        case .dancing: "💃"
        case .photography: "📸"
        case .nature: "🌿"
        case .coffee: "☕️"
        }
    }
}

enum Relationship: String, CaseIterable, Codable, Identifiable {
    case girlfriend
    case friend
    case crush
    case colleague
    case neighbor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .girlfriend: LocalizedText("Girlfriend", ru: "Девушка").value
        case .friend: LocalizedText("Best friend", ru: "Подруга").value
        case .crush: LocalizedText("New crush", ru: "Новая знакомая").value
        case .colleague: LocalizedText("Colleague", ru: "Коллега").value
        case .neighbor: LocalizedText("Neighbor", ru: "Соседка").value
        }
    }

    var icon: String {
        switch self {
        case .girlfriend: "heart.fill"
        case .friend: "person.2.fill"
        case .crush: "sparkles"
        case .colleague: "briefcase.fill"
        case .neighbor: "house.fill"
        }
    }

    var promptDescription: String {
        switch self {
        case .girlfriend: "you are the user's girlfriend, affectionate and close"
        case .friend: "you are the user's close friend with a hint of chemistry"
        case .crush: "you met the user recently online and there is a spark between you"
        case .colleague: "you work with the user and enjoy chatting after work"
        case .neighbor: "you live next door to the user and keep running into each other"
        }
    }
}

enum VoiceStyle: String, CaseIterable, Codable, Identifiable {
    case soft
    case sweet
    case warm
    case bright
    case calm
    case velvet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .soft: LocalizedText("Soft", ru: "Нежный").value
        case .sweet: LocalizedText("Sweet", ru: "Милый").value
        case .warm: LocalizedText("Warm", ru: "Тёплый").value
        case .bright: LocalizedText("Bright", ru: "Звонкий").value
        case .calm: LocalizedText("Calm", ru: "Спокойный").value
        case .velvet: LocalizedText("Velvet", ru: "Бархатный").value
        }
    }

    var subtitle: String {
        switch self {
        case .soft: LocalizedText("Gentle and quiet", ru: "Тихий и ласковый").value
        case .sweet: LocalizedText("Playful and cute", ru: "Игривый и милый").value
        case .warm: LocalizedText("Cozy and caring", ru: "Уютный и заботливый").value
        case .bright: LocalizedText("Energetic and fun", ru: "Энергичный и весёлый").value
        case .calm: LocalizedText("Slow and soothing", ru: "Медленный и успокаивающий").value
        case .velvet: LocalizedText("Low and seductive", ru: "Низкий и чарующий").value
        }
    }

    var rateMultiplier: Float {
        switch self {
        case .soft: 0.92
        case .sweet: 1.0
        case .warm: 0.95
        case .bright: 1.06
        case .calm: 0.88
        case .velvet: 0.9
        }
    }

    /// Selects different female system voices for different styles when several are installed.
    var voicePreferenceOffset: Int {
        switch self {
        case .soft: 0
        case .sweet: 1
        case .warm: 2
        case .bright: 1
        case .calm: 0
        case .velvet: 2
        }
    }

    /// Female voice of the LLMApps text-to-speech model (Kling TTS voice IDs).
    var cloudVoiceID: String {
        switch self {
        case .soft: "chat1_female_new-3"
        case .sweet: "girlfriend_4_speech02"
        case .warm: "ai_shatang"
        case .bright: "ai_kaiya"
        case .calm: "genshin_kirara"
        case .velvet: "chat_0407_5-1"
        }
    }

    /// Speech speed for the cloud voice; the provider accepts 0.8...2.
    var cloudSpeed: Double {
        min(2, max(0.8, Double(rateMultiplier)))
    }

    var sample: String {
        LocalizedText(
            "Hey, it's me. I was just thinking about you… How was your day?",
            ru: "Привет, это я. Как раз думала о тебе… Как прошёл твой день?"
        ).value
    }
}

enum Ethnicity: String, CaseIterable, Codable, Identifiable {
    case caucasian
    case latina
    case asian
    case black
    case slavic
    case arab
    case mixed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .caucasian: LocalizedText("European appearance", ru: "Европейская внешность").value
        case .latina: LocalizedText("Latina", ru: "Латина").value
        case .asian: LocalizedText("Asian", ru: "Азиатка").value
        case .black: LocalizedText("African appearance", ru: "Африканская внешность").value
        case .slavic: LocalizedText("Slavic", ru: "Славянка").value
        case .arab: LocalizedText("Arab", ru: "Арабка").value
        case .mixed: LocalizedText("Mixed", ru: "Метиска").value
        }
    }

    var exampleAsset: String {
        switch self {
        case .caucasian: "mia_00"
        case .latina: "sofia_00"
        case .asian: "yuna_00"
        case .black: "amara_00"
        case .slavic: "elena_00"
        case .arab: "layla_00"
        case .mixed: "naomi_00"
        }
    }

    var prompt: String {
        switch self {
        case .caucasian: "Caucasian"
        case .latina: "Latina"
        case .asian: "East Asian"
        case .black: "Black"
        case .slavic: "Slavic Eastern European"
        case .arab: "Middle Eastern Arab"
        case .mixed: "mixed-race"
        }
    }
}

enum EyeColor: String, CaseIterable, Codable, Identifiable {
    case brown
    case blue
    case green
    case hazel
    case grey

    var id: String { rawValue }

    var title: String {
        switch self {
        case .brown: LocalizedText("Brown", ru: "Карие").value
        case .blue: LocalizedText("Blue", ru: "Голубые").value
        case .green: LocalizedText("Green", ru: "Зелёные").value
        case .hazel: LocalizedText("Hazel", ru: "Ореховые").value
        case .grey: LocalizedText("Grey", ru: "Серые").value
        }
    }

    var swatch: UInt32 {
        switch self {
        case .brown: 0x6B4226
        case .blue: 0x4A90D9
        case .green: 0x4E9A5B
        case .hazel: 0x9C7A3C
        case .grey: 0x8E9AA6
        }
    }
}

enum HairStyle: String, CaseIterable, Codable, Identifiable {
    case longStraight
    case longWavy
    case curly
    case bob
    case ponytail
    case bangs
    case braids

    var id: String { rawValue }

    var title: String {
        switch self {
        case .longStraight: LocalizedText("Long straight", ru: "Длинные прямые").value
        case .longWavy: LocalizedText("Long wavy", ru: "Длинные волнистые").value
        case .curly: LocalizedText("Curly", ru: "Кудрявые").value
        case .bob: LocalizedText("Bob", ru: "Каре").value
        case .ponytail: LocalizedText("Ponytail", ru: "Хвост").value
        case .bangs: LocalizedText("With bangs", ru: "С чёлкой").value
        case .braids: LocalizedText("Braids", ru: "Косички").value
        }
    }

    var prompt: String {
        switch self {
        case .longStraight: "long straight"
        case .longWavy: "long wavy"
        case .curly: "voluminous curly"
        case .bob: "chin-length bob"
        case .ponytail: "high ponytail"
        case .bangs: "shoulder-length with soft bangs"
        case .braids: "long braided"
        }
    }
}

enum HairColor: String, CaseIterable, Codable, Identifiable {
    case brunette
    case blonde
    case black
    case red
    case auburn
    case pink

    var id: String { rawValue }

    var title: String {
        switch self {
        case .brunette: LocalizedText("Brunette", ru: "Шатенка").value
        case .blonde: LocalizedText("Blonde", ru: "Блондинка").value
        case .black: LocalizedText("Black", ru: "Брюнетка").value
        case .red: LocalizedText("Ginger", ru: "Рыжая").value
        case .auburn: LocalizedText("Auburn", ru: "Каштановая").value
        case .pink: LocalizedText("Pink", ru: "Розовые").value
        }
    }

    var swatch: UInt32 {
        switch self {
        case .brunette: 0x5A3A22
        case .blonde: 0xE8C77E
        case .black: 0x1C1A19
        case .red: 0xC4572B
        case .auburn: 0x7E3B26
        case .pink: 0xF39AB7
        }
    }

    var prompt: String {
        switch self {
        case .brunette: "brown"
        case .blonde: "blonde"
        case .black: "jet-black"
        case .red: "natural ginger red"
        case .auburn: "auburn"
        case .pink: "pastel pink dyed"
        }
    }
}

enum BodyType: String, CaseIterable, Codable, Identifiable {
    case slim
    case athletic
    case average
    case curvy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .slim: LocalizedText("Slim", ru: "Стройная").value
        case .athletic: LocalizedText("Athletic", ru: "Спортивная").value
        case .average: LocalizedText("Average", ru: "Средняя").value
        case .curvy: LocalizedText("Curvy", ru: "Пышная").value
        }
    }

    var icon: String {
        switch self {
        case .slim: "figure.stand"
        case .athletic: "figure.run"
        case .average: "figure.walk"
        case .curvy: "figure.dance"
        }
    }

    var prompt: String {
        switch self {
        case .slim: "slim"
        case .athletic: "athletic toned"
        case .average: "average"
        case .curvy: "curvy"
        }
    }
}
