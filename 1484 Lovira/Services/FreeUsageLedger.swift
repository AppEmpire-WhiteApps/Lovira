import Foundation
import Observation

/// Device-local free allowances, independent of chat deletion and disappearing messages.
@Observable
final class FreeUsageLedger {
    static let dailyMessageLimit = 20
    private let defaults: UserDefaults
    private let storageKey = "lovira.freeUsage.v1"
    private var state: State
    private var pendingMessages: [UUID: String] = [:]
    private var pendingPhotos: [String: UUID] = [:]

    private struct State: Codable {
        var day = ""
        var messages = 0
        var characterActions = 0
        var firstChatPhotoIDs: [String: String] = [:]
        var galleryPhotoKeys: [String: String] = [:]
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey), let saved = try? JSONDecoder().decode(State.self, from: data) {
            state = saved
        } else {
            state = State()
        }
    }

    var canCreateCharacter: Bool { state.characterActions == 0 }

    func recordCharacterAction() {
        state.characterActions += 1
        save()
    }

    func accountForExistingCharacters(_ count: Int) {
        if count > 0, state.characterActions == 0 {
            state.characterActions = count
            save()
        }
    }

    var remainingMessages: Int {
        remainingMessages(at: .now)
    }

    func remainingMessages(at date: Date) -> Int {
        let day = Self.dayKey(date)
        let used = state.day == day ? state.messages : 0
        let reserved = pendingMessages.values.filter { $0 == day }.count
        return max(0, Self.dailyMessageLimit - used - reserved)
    }

    /// Reserves a slot before the network request so concurrent chats cannot exceed the limit.
    func reserveMessage(_ id: UUID, premium: Bool, alreadyCharged: Bool, at date: Date = .now) -> Bool {
        guard pendingMessages[id] == nil else { return false }
        if premium || alreadyCharged { return true }
        guard remainingMessages(at: date) > 0 else { return false }
        pendingMessages[id] = Self.dayKey(date)
        return true
    }

    /// Charges only successful replies, on the day the request was accepted.
    func finishMessage(_ id: UUID, success: Bool, at date: Date = .now) {
        guard let reservedDay = pendingMessages.removeValue(forKey: id), success else { return }
        let today = Self.dayKey(date)
        guard reservedDay == today else { return }
        if state.day != today {
            state.day = today
            state.messages = 0
        }
        state.messages += 1
        save()
    }

    func firstChatPhotoID(for companionID: String) -> String? {
        state.firstChatPhotoIDs[companionID]
    }

    func canReceivePhoto(from companionID: String) -> Bool {
        state.firstChatPhotoIDs[companionID] == nil && pendingPhotos[companionID] == nil
    }

    func reservePhoto(from companionID: String, premium: Bool, reservationID: UUID) -> Bool {
        if premium { return true }
        if pendingPhotos[companionID] == reservationID { return true }
        guard canReceivePhoto(from: companionID) else { return false }
        pendingPhotos[companionID] = reservationID
        return true
    }

    func cancelPhotoReservation(from companionID: String, reservationID: UUID) {
        if pendingPhotos[companionID] == reservationID {
            pendingPhotos.removeValue(forKey: companionID)
        }
    }

    func finishPhoto(from companionID: String, messageID: UUID, success: Bool, reservationID: UUID? = nil) {
        if let reservationID {
            cancelPhotoReservation(from: companionID, reservationID: reservationID)
        }
        if success, state.firstChatPhotoIDs[companionID] == nil {
            state.firstChatPhotoIDs[companionID] = messageID.uuidString
            save()
        }
    }

    func galleryPhotoKey(for companionID: String) -> String? {
        state.galleryPhotoKeys[companionID]
    }

    func registerGalleryPhoto(key: String, companionID: String) {
        guard state.galleryPhotoKeys[companionID] == nil else { return }
        state.galleryPhotoKeys[companionID] = key
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private static func dayKey(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }
}
