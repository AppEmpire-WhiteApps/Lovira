import Foundation
import LocalAuthentication
import Observation
import UIKit

/// Face ID / Touch ID / passcode app lock.
@Observable
final class AppLock {
    private(set) var isLocked = false
    private var isAuthenticating = false

    static var biometryName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return LocalizedText("Passcode", ru: "Код-пароль").value
        }
    }

    static var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    func lock() {
        isLocked = true
    }

    func unlock() async {
        guard isLocked, !isAuthenticating else {
            return
        }
        if await authenticate() {
            isLocked = false
        }
    }

    /// Asks for authentication; used for unlocking and for enabling the lock.
    func authenticate() async -> Bool {
        isAuthenticating = true
        defer { isAuthenticating = false }
        let context = LAContext()
        let reason = LocalizedText("Unlock the app", ru: "Разблокировать приложение").value
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}

enum Haptics {
    static var isEnabled = true

    static func tap() {
        guard isEnabled else {
            return
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        guard isEnabled else {
            return
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        guard isEnabled else {
            return
        }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
