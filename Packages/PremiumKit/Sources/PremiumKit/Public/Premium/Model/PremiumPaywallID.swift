public struct PremiumPaywallID: Hashable, Sendable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
    
    public static let onboarding = PremiumPaywallID(PremiumKitTablee4a25abbda068453.placement(0))
    public static let main = PremiumPaywallID(PremiumKitTablee4a25abbda068453.placement(1))
    public static let consumable = PremiumPaywallID(PremiumKitTablee4a25abbda068453.placement(2))
    public static let banner = PremiumPaywallID(PremiumKitTablee4a25abbda068453.placement(3))
    
    public var isAvailablePaywall: Bool {
        self == .main || self == .onboarding
    }
}
