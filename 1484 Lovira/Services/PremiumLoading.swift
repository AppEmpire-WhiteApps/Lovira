import PremiumKit

extension AppModel {
    func loadMainPaywall() async {
        await Premium.shared.loadPaywall(.main)
        isMainPaywallLoaded = true
    }

    func loadScenarioPaywall() async {
        await Premium.shared.loadPaywall(PremiumRoute.scenarios.paywallID)
        isScenarioPaywallLoaded = true
    }
}
