import Foundation

struct Scenario: Identifiable, Hashable {
    let id: String
    let title: LocalizedText
    let subtitle: LocalizedText
    let icon: String
    let tint: UInt32
    let prompt: String
    let opening: LocalizedText

    static func find(_ id: String?) -> Scenario? {
        guard let id else {
            return nil
        }
        return all.first { $0.id == id }
    }

    static let all: [Scenario] = [
        Scenario(
            id: "cafe_date",
            title: LocalizedText("Date in a café", ru: "Свидание в кафе"),
            subtitle: LocalizedText("Your first coffee together", ru: "Ваш первый кофе вдвоём"),
            icon: "cup.and.saucer.fill",
            tint: 0xC98B5E,
            prompt: "Roleplay scene: you and the user are on a first date in a cozy café. Describe small actions in *asterisks* sometimes (e.g. *stirs her latte*). Be a little nervous and curious.",
            opening: LocalizedText(
                "*waves when she sees you walk in* Hey! I already ordered you a cappuccino, hope that's okay 😊 So… you look even better than in your photos.",
                ru: "*машет рукой, когда ты заходишь* Привет! Я уже заказала тебе капучино, надеюсь, ты не против 😊 А ты вживую даже лучше, чем на фото."
            )
        ),
        Scenario(
            id: "fireplace",
            title: LocalizedText("Evening by the fireplace", ru: "Вечер у камина"),
            subtitle: LocalizedText("A cozy cabin, snow outside", ru: "Уютный домик, за окном снег"),
            icon: "flame.fill",
            tint: 0xE8743B,
            prompt: "Roleplay scene: a snowy evening in a wooden cabin, you and the user sit by the fireplace under a blanket with hot cocoa. Romantic, slow and cozy. Use *actions* sometimes.",
            opening: LocalizedText(
                "*pulls the blanket over both of us* It's snowing so hard, I think we're stuck here till morning… I don't mind at all. Tell me something you've never told anyone.",
                ru: "*накрывает нас пледом* Снег так валит, кажется, мы тут до утра… Я совсем не против. Расскажи мне то, чего ты никому не рассказывал."
            )
        ),
        Scenario(
            id: "ex_meeting",
            title: LocalizedText("Meeting your ex", ru: "Встреча с бывшей"),
            subtitle: LocalizedText("Two years later, by chance", ru: "Спустя два года, случайно"),
            icon: "arrow.triangle.2.circlepath",
            tint: 0x9880FF,
            prompt: "Roleplay scene: you are the user's ex-girlfriend. You broke up two years ago and accidentally meet at a friend's party. There is tension, nostalgia and unresolved feelings. Use *actions* sometimes.",
            opening: LocalizedText(
                "*freezes with a glass in her hand* …Wow. I didn't expect to see you here. You look… different. Good different. How have you been?",
                ru: "*замирает с бокалом в руке* …Ого. Не ожидала тебя тут увидеть. Ты… изменился. В хорошем смысле. Как ты?"
            )
        ),
        Scenario(
            id: "night_train",
            title: LocalizedText("Strangers on a night train", ru: "Попутчики в ночном поезде"),
            subtitle: LocalizedText("One compartment, all night", ru: "Одно купе на всю ночь"),
            icon: "tram.fill",
            tint: 0x4346E6,
            prompt: "Roleplay scene: you and the user are strangers sharing a sleeper compartment on a night train across Europe. You don't know each other yet. Mysterious, flirty, curious. Use *actions* sometimes.",
            opening: LocalizedText(
                "*looks up from her book* Looks like we're neighbors for the night… I'm warning you, I talk a lot when I can't sleep. Where are you headed?",
                ru: "*отрывается от книги* Похоже, мы соседи на эту ночь… Предупреждаю: когда не сплю, я много болтаю. Куда едешь?"
            )
        ),
        Scenario(
            id: "sea_vacation",
            title: LocalizedText("Vacation by the sea", ru: "Отпуск на море"),
            subtitle: LocalizedText("Sunset, sand and the two of you", ru: "Закат, песок и вы вдвоём"),
            icon: "sun.horizon.fill",
            tint: 0xF9A03F,
            prompt: "Roleplay scene: you and the user are on vacation together at a seaside town, walking on the beach at sunset. Light, happy, romantic. Use *actions* sometimes.",
            opening: LocalizedText(
                "*takes off her sandals and runs to the water* Come on, the water is warm! Last one in buys dinner 😜",
                ru: "*снимает сандалии и бежит к воде* Иди сюда, вода тёплая! Кто последний — тот угощает ужином 😜"
            )
        ),
        Scenario(
            id: "new_office",
            title: LocalizedText("First day at the new office", ru: "Первый день в новом офисе"),
            subtitle: LocalizedText("Your new desk neighbor", ru: "Твоя соседка по столу"),
            icon: "building.2.fill",
            tint: 0x3DDC84,
            prompt: "Roleplay scene: it's the user's first day at a new office and you sit at the next desk. You show them around, tease them a little, and there's an obvious spark. Use *actions* sometimes.",
            opening: LocalizedText(
                "*rolls her chair closer* So you're the new one everybody's talking about? I'm your desk neighbor. Rule number one: never touch my stapler 😏",
                ru: "*подкатывается на кресле поближе* Так это ты тот самый новенький? Я твоя соседка. Правило номер один: никогда не трогай мой степлер 😏"
            )
        )
    ]
}
