import ApphudSDK
import Foundation
import StoreKit

/// Immutable entitlement IDs evaluated at initialization, never accumulated from purchase history.
struct PremiumEntitlementSnapshot {
    let activeProductIDs: Set<String>

    var isPremium: Bool {
        !activeProductIDs.isEmpty
    }

    init(
        subscriptions: [ApphudSubscription],
        purchases: [ApphudNonRenewingPurchase],
        localStoreKit: LocalStoreKitEntitlementSnapshot? = nil,
        now: Date = Date()
    ) {
        if let localStoreKit {
            // An empty local snapshot is authoritative too (expiry, refund, or cleared purchases).
            activeProductIDs = localStoreKit.activeProductIDs(at: now)
            return
        }
        let subscriptionIDs = subscriptions.filter { $0.isActive() }.map(\.productId)
        let purchaseIDs = purchases.filter { $0.isActive() }.map(\.productId)
        activeProductIDs = Set(subscriptionIDs).union(purchaseIDs)
    }
}

/// Only PaymentManager's DEBUG verified .xcode path supplies these value snapshots.
struct LocalStoreKitEntitlementSnapshot {
    struct Entitlement {
        let productID: String
        let productType: Product.ProductType
        let expirationDate: Date?
        let revocationDate: Date?
        let isUpgraded: Bool
        let isXcodeEnvironment: Bool

        init(verifiedTransaction transaction: StoreKit.Transaction) {
            productID = transaction.productID
            productType = transaction.productType
            expirationDate = transaction.expirationDate
            revocationDate = transaction.revocationDate
            isUpgraded = transaction.isUpgraded
            isXcodeEnvironment = transaction.environment == .xcode
        }

        init(
            productID: String,
            productType: Product.ProductType,
            expirationDate: Date?,
            revocationDate: Date? = nil,
            isUpgraded: Bool = false,
            isXcodeEnvironment: Bool = true
        ) {
            self.productID = productID
            self.productType = productType
            self.expirationDate = expirationDate
            self.revocationDate = revocationDate
            self.isUpgraded = isUpgraded
            self.isXcodeEnvironment = isXcodeEnvironment
        }

        func isActive(at now: Date) -> Bool {
            guard isXcodeEnvironment, revocationDate == nil, !isUpgraded else { return false }
            switch productType {
            case .nonConsumable:
                return expirationDate.map { $0 > now } ?? true
            case .autoRenewable, .nonRenewable:
                // Never invent a lifetime for a non-renewing transaction without an expiry.
                return expirationDate.map { $0 > now } ?? false
            default:
                return false
            }
        }
    }

    let entitlements: [Entitlement]

    func activeProductIDs(at now: Date) -> Set<String> {
        Set(entitlements.filter { $0.isActive(at: now) }.map(\.productID))
    }
}
