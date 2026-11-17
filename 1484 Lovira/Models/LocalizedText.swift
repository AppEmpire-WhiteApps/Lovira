import Foundation

enum AppLanguage {
    static var isRussian: Bool {
        let preferred = Bundle.main.preferredLocalizations.first ?? Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("ru")
    }

    static var code: String {
        isRussian ? "ru" : "en"
    }
}

struct LocalizedText: Hashable {
    let en: String
    let ru: String

    init(_ en: String, ru: String) {
        self.en = en
        self.ru = ru
    }

    var value: String {
        AppLanguage.isRussian ? ru : en
    }
}
