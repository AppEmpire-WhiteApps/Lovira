import Foundation
import Observation

/// Explicit consent for the current version of AI data sharing.
@MainActor
@Observable
final class AIConsentStore {
    static let shared = AIConsentStore()

    // A new disclosure version must use a new key; older consent is not migrated.
    private static let acceptanceKey = "aiDataSharingConsent.v1.accepted"

    private(set) var hasGranted: Bool
    private(set) var isPresented = false

    @ObservationIgnored private var onApprove: (() -> Void)?
    @ObservationIgnored private var onCancel: (() -> Void)?

    private init() {
        hasGranted = UserDefaults.standard.bool(forKey: Self.acceptanceKey)
    }

    /// Returns true only when consent was already granted. The caller can then proceed.
    /// Otherwise, only the first pending request owns the alert's callbacks.
    @discardableResult
    func request(
        onApprove: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) -> Bool {
        guard !hasGranted else {
            return true
        }
        guard !isPresented else {
            return false
        }

        self.onApprove = onApprove
        self.onCancel = onCancel
        isPresented = true
        return false
    }

    func accept() {
        guard isPresented else {
            return
        }

        UserDefaults.standard.set(true, forKey: Self.acceptanceKey)
        hasGranted = true
        let approval = onApprove
        clearPresentation()
        approval?()
    }

    /// Pass false when the owning presenter disappears to avoid a second dismissal.
    func cancel(notifyCancellation: Bool = true) {
        guard isPresented else {
            return
        }

        let cancellation = notifyCancellation ? onCancel : nil
        clearPresentation()
        cancellation?()
    }

    private func clearPresentation() {
        isPresented = false
        onApprove = nil
        onCancel = nil
    }
}

enum AIConsentError: LocalizedError {
    case required

    var errorDescription: String? {
        switch self {
        case .required:
            return LocalizedText(
                "Your consent to AI data processing is required to use this feature.",
                ru: "Для использования этой функции необходимо ваше согласие на обработку данных с помощью ИИ."
            ).value
        }
    }
}
