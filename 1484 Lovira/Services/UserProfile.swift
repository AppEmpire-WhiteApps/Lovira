import Foundation
import Observation

enum LookingFor: String, CaseIterable, Identifiable {
    case conversation
    case romance
    case roleplay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .conversation: LocalizedText("Conversation", ru: "Общение").value
        case .romance: LocalizedText("Romance", ru: "Романтика").value
        case .roleplay: LocalizedText("Roleplay", ru: "Ролевые игры").value
        }
    }

    var icon: String {
        switch self {
        case .conversation: "bubble.left.and.bubble.right.fill"
        case .romance: "heart.fill"
        case .roleplay: "theatermasks.fill"
        }
    }
}

enum DisappearOption: Double, CaseIterable, Identifiable {
    case off = 0
    case day = 86_400
    case week = 604_800

    var id: Double { rawValue }

    var title: String {
        switch self {
        case .off: LocalizedText("Off", ru: "Выкл.").value
        case .day: LocalizedText("24 hours", ru: "24 часа").value
        case .week: LocalizedText("7 days", ru: "7 дней").value
        }
    }
}

enum Achievement: String, CaseIterable, Identifiable {
    case firstMessage
    case hundredMessages
    case firstPhoto
    case createdCharacter
    case firstScenario

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstMessage: LocalizedText("First hello", ru: "Первое сообщение").value
        case .hundredMessages: LocalizedText("Chatterbox", ru: "100 сообщений").value
        case .firstPhoto: LocalizedText("First photo", ru: "Первое фото").value
        case .createdCharacter: LocalizedText("Creator", ru: "Создатель").value
        case .firstScenario: LocalizedText("Storyteller", ru: "Первый сценарий").value
        }
    }

    var subtitle: String {
        switch self {
        case .firstMessage: LocalizedText("Send your first message", ru: "Отправь первое сообщение").value
        case .hundredMessages: LocalizedText("Send 100 messages", ru: "Отправь 100 сообщений").value
        case .firstPhoto: LocalizedText("Receive your first photo", ru: "Получи первое фото").value
        case .createdCharacter: LocalizedText("Create your own character", ru: "Создай своего персонажа").value
        case .firstScenario: LocalizedText("Start a roleplay scenario", ru: "Запусти ролевой сценарий").value
        }
    }

    var icon: String {
        switch self {
        case .firstMessage: "bubble.left.fill"
        case .hundredMessages: "text.bubble.fill"
        case .firstPhoto: "photo.fill"
        case .createdCharacter: "wand.and.stars"
        case .firstScenario: "theatermasks.fill"
        }
    }
}

/// User preferences, onboarding flags and achievements stored in UserDefaults.
@Observable
final class UserProfile {
    private let defaults: UserDefaults

    var hasConfirmedAge: Bool { didSet { save(hasConfirmedAge, "hasConfirmedAge") } }
    var hasOnboarded: Bool { didSet { save(hasOnboarded, "hasOnboarded") } }
    var userName: String { didSet { save(userName, "userName") } }
    var lookingForRaw: String { didSet { save(lookingForRaw, "lookingFor") } }
    var autoVoiceReplies: Bool { didSet { save(autoVoiceReplies, "autoVoiceReplies") } }
    var appLockEnabled: Bool { didSet { save(appLockEnabled, "appLockEnabled") } }
    var defaultDisappearRaw: Double { didSet { save(defaultDisappearRaw, "defaultDisappear") } }
    var hapticsEnabled: Bool { didSet { save(hapticsEnabled, "hapticsEnabled") } }
    var totalMessages: Int { didSet { save(totalMessages, "totalMessages") } }
    var achievementsRaw: [String] { didSet { save(achievementsRaw, "achievements") } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasConfirmedAge = defaults.bool(forKey: "hasConfirmedAge")
        hasOnboarded = defaults.bool(forKey: "hasOnboarded")
        userName = defaults.string(forKey: "userName") ?? ""
        lookingForRaw = defaults.string(forKey: "lookingFor") ?? LookingFor.romance.rawValue
        autoVoiceReplies = defaults.bool(forKey: "autoVoiceReplies")
        appLockEnabled = defaults.bool(forKey: "appLockEnabled")
        defaultDisappearRaw = defaults.double(forKey: "defaultDisappear")
        hapticsEnabled = defaults.object(forKey: "hapticsEnabled") as? Bool ?? true
        totalMessages = defaults.integer(forKey: "totalMessages")
        achievementsRaw = defaults.stringArray(forKey: "achievements") ?? []
    }

    var lookingFor: LookingFor {
        get { LookingFor(rawValue: lookingForRaw) ?? .romance }
        set { lookingForRaw = newValue.rawValue }
    }

    var defaultDisappear: DisappearOption {
        get { DisappearOption(rawValue: defaultDisappearRaw) ?? .off }
        set { defaultDisappearRaw = newValue.rawValue }
    }

    var displayName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? LocalizedText("Darling", ru: "Милый").value : trimmed
    }

    // MARK: Achievements

    func hasAchievement(_ achievement: Achievement) -> Bool {
        achievementsRaw.contains(achievement.rawValue)
    }

    /// Grants the achievement once and returns it when newly unlocked.
    func unlock(_ achievement: Achievement) -> Achievement? {
        guard !hasAchievement(achievement) else {
            return nil
        }
        achievementsRaw.append(achievement.rawValue)
        return achievement
    }

    func resetAll() {
        let keys = [
            "hasOnboarded", "userName", "lookingFor", "autoVoiceReplies", "appLockEnabled",
            "defaultDisappear", "hapticsEnabled", "totalMessages", "achievements"
        ]
        keys.forEach(defaults.removeObject(forKey:))
        userName = ""
        lookingForRaw = LookingFor.romance.rawValue
        autoVoiceReplies = false
        appLockEnabled = false
        defaultDisappearRaw = 0
        hapticsEnabled = true
        totalMessages = 0
        achievementsRaw = []
        hasOnboarded = false
    }

    private func save(_ value: Any, _ key: String) {
        defaults.set(value, forKey: key)
    }
}
