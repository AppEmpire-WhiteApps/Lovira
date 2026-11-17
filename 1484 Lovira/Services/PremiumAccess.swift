import Combine
import Foundation
import Observation
import PremiumKit

/// Scenarios require both general premium and an active product from their own placement.
enum PremiumFeature {
    case scenarios
    case voice
    case fastReplies
    case characterCreate
    case characterEdit
}

enum PremiumRoute: String, Identifiable {
    case main
    case scenarios

    var id: String { rawValue }
    var paywallID: PremiumPaywallID {
        switch self {
        case .main: .main
        case .scenarios: PremiumPaywallID("aiChat")
        }
    }
}

/// Reactive forwarding of PremiumKit's entitlement, plus the app's free allowance policy.
@Observable
final class PremiumAccess {
    let usage: FreeUsageLedger
    private(set) var isPremium = false
    private var hasScenarioSubscription = false

    var hasScenarioAccess: Bool {
        isPremium && hasScenarioSubscription
    }
    @ObservationIgnored private var subscription: AnyCancellable?
    @ObservationIgnored private var scenarioSubscription: AnyCancellable?
    private let freeCompanionIDs: Set<String> = ["mia", "sofia", "yuna", "amara"]

    init(
        usage: FreeUsageLedger = FreeUsageLedger(),
        entitlement: AnyPublisher<Bool, Never>? = nil,
        scenarioEntitlement: AnyPublisher<Bool, Never>? = nil
    ) {
        self.usage = usage
        let publisher = entitlement ?? Premium.shared.$isPremium.eraseToAnyPublisher()
        subscription = publisher.sink { [weak self] value in
            self?.isPremium = value
        }

        let scenarioPublisher: AnyPublisher<Bool, Never>
        if let scenarioEntitlement {
            scenarioPublisher = scenarioEntitlement
        } else if entitlement != nil {
            // Injecting general access alone must never grant scenario access.
            scenarioPublisher = Just(false).eraseToAnyPublisher()
        } else {
            scenarioPublisher = Premium.shared.$activeProductIds
                .combineLatest(Premium.shared.$paywalls)
                // @Published emits in willSet; read SDK state after both stores update.
                .receive(on: DispatchQueue.main)
                .map { _ in
                    Premium.shared.hasActiveProduct(fromPaywall: PremiumRoute.scenarios.paywallID)
                }
                .eraseToAnyPublisher()
        }
        scenarioSubscription = scenarioPublisher.sink { [weak self] value in
            self?.hasScenarioSubscription = value
        }
    }

    func allows(_ feature: PremiumFeature) -> Bool {
        if feature == .scenarios {
            return hasScenarioAccess
        }
        return isPremium || (feature == .characterCreate && usage.canCreateCharacter)
    }

    func isCharacterAvailable(_ companion: Companion) -> Bool {
        isPremium || companion.isCustom || freeCompanionIDs.contains(companion.id)
    }

    func recordCharacterAction() {
        usage.recordCharacterAction()
    }
}

/// Configure before PremiumAppDelegate starts Apphud. The fallback resource is authenticated ciphertext.
enum PremiumSetup {
    static var apiKey: String { ApphudCredentials.apiKey }
    static var isConfigured: Bool { !apiKey.isEmpty }

    static func configureIfReady() {
        guard isConfigured else { return }
        Premium.shared.configure(
            PremiumConfiguration(
                apiKey: apiKey,
                supportedLanguages: [.en, .ru],
                defaultLanguage: .en,
                fallbackFileName: "pk_62318d058639b2e1352d124d"
            ))
    }
}
