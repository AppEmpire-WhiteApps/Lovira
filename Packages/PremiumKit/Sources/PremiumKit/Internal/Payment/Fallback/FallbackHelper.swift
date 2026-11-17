import Foundation
import StoreKit
@preconcurrency import ApphudSDK

@MainActor
class FallbackHelper {
    private var storeLoads: [PremiumPaywallID: Task<[String: Product], Error>] = [:]
    private var eligibilityLoads: [PremiumPaywallID: Task<[String: Bool], Error>] = [:]

    func fallbackToPaywallModel(for id: PremiumPaywallID, fileName: String) async -> PaywallModel {
        
        guard let paywallFallback = loadFallbackPaywall(id, fileName: fileName) else { return .init(id: id) }

        let storeProducts = await loadStoreProducts(
            for: paywallFallback.products.map(\.id),
            paywallID: id
        )
        let eligibility = await loadEligibility(for: storeProducts, paywallID: id)
        var products: [ProductModel] = []
        
        for fallbackProduct in paywallFallback.products {
            let storeProduct = storeProducts[fallbackProduct.id]
            let localProduct = storeProduct == nil ? skFind(productId: fallbackProduct.id) : nil
            let localPrice = localProduct?.displayPrice
            let localSubscriptionPeriod = localProduct?.recurringSubscriptionPeriod

            let isLifetime = storeProduct.map { $0.type == .nonConsumable }
                ?? (localProduct != nil && localSubscriptionPeriod == nil)

            let configPeriodly = L10n.resolve(fallbackProduct.periodly)
            ///Период ищем и в сыром ключе, и в локализованном значении — periodly может быть ключом локализации
            let periodSource = "\(fallbackProduct.periodly) \(configPeriodly)".lowercased()

            let pricePerPeriod: String = {
                if let storeProduct {
                    return ApphudProduct.pricePerPeriodFromSK2Product(storeProduct)
                }
                if let price = localPrice {
                    return perPeriodString(price: price, period: localSubscriptionPeriod)
                } else {
                    switch periodSource {
                    case let period where period.contains("week"):  return "$4.99/\(L10n.Period.week)"
                    case let period where period.contains("month"): return "$12.99/\(L10n.Period.month)"
                    case let period where period.contains("year"):  return "$39.99/\(L10n.Period.year)"
                    default:                                        return "$59.99/\(L10n.Period.oneTime)"
                    }
                }
            }()

            let pricePerWeek: String = {
                let lifetimeText = configPeriodly.isEmpty ? L10n.Price.limitedOffer : configPeriodly

                if let storeProduct {
                    if isLifetime { return lifetimeText }
                    return ApphudProduct.pricePerWeekFromSK2Product(storeProduct)
                }
                if let price = localPrice {
                    guard localSubscriptionPeriod != nil else { return lifetimeText }
                    return perWeekString(price: price, period: localSubscriptionPeriod)
                } else {
                    switch periodSource {
                    case let period where period.contains("week"):  return L10n.Price.perWeek("$4.99")
                    case let period where period.contains("month"): return L10n.Price.perWeek("$3.24")
                    case let period where period.contains("year"):  return L10n.Price.perWeek("$0.83")
                    default:                                        return lifetimeText
                    }
                }
            }()

            var isTrial = false
            var trialDuration: String? = nil
            var subscriptionDuration: String? = nil
            if let subscription = storeProduct?.subscription {
                let isEligible = eligibility[fallbackProduct.id] ?? false
                isTrial = isEligible && subscription.introductoryOffer != nil
                subscriptionDuration = ApphudProduct.humanReadablePeriodSK2(subscription.subscriptionPeriod)

                if let offer = subscription.introductoryOffer, offer.paymentMode == .freeTrial {
                    trialDuration = ApphudProduct.humanReadablePeriodSK2(offer.period)
                }
            }
            
            let product: ProductModel
            product = ProductModel(
                id: fallbackProduct.id,
                title: L10n.resolve(fallbackProduct.title),
                subtitle: L10n.resolveOptional(fallbackProduct.subtitle),
                nonTrialSubtitle: L10n.resolveOptional(fallbackProduct.nonTrialSubtitle),
                message: L10n.resolveOptional(fallbackProduct.message),
                periodly: L10n.resolve(fallbackProduct.periodly),
                pricePerPeriod: pricePerPeriod,
                pricePerWeek: pricePerWeek,
                isTrial: isTrial,
                isLifetime: isLifetime,
                consumable: fallbackProduct.consumable,
                consumableUnit: fallbackProduct.consumableUnit,
                trialDuration: trialDuration,
                subscriptionDuration: subscriptionDuration
            )
            products.append(product)
        }
        
        let paywall = PaywallModel(id: id,
                                   title: L10n.localized(paywallFallback.title),
                                   tryFreeButton: L10n.localized(paywallFallback.tryFreeButton ?? "button.try_free"),
                                   continueButton: L10n.localized(paywallFallback.continueButton ?? "button.continue"),
                                   purchaseButton: L10n.localized(paywallFallback.purchaseButton ?? "button.purchase"),
                                   limitedButton: L10n.localized(paywallFallback.limitedButton ?? "button.limited"),
                                   configuration: PaywallConfiguration(paywallFallback.configurationAB ?? "variant1"),
                                   products: products,
                                   showRequestReview: paywallFallback.showRequestReview ?? true)
        
        return paywall
    }

    private func loadStoreProducts(
        for productIDs: [String],
        paywallID: PremiumPaywallID
    ) async -> [String: Product] {
        guard !productIDs.isEmpty, !Task.isCancelled else { return [:] }

        let task: Task<[String: Product], Error>
        if let pending = storeLoads[paywallID] {
            task = pending
        } else {
            task = Task { @MainActor in
                defer { self.storeLoads[paywallID] = nil }
                try Task.checkCancellation()
                let products = try await Product.products(for: productIDs)
                try Task.checkCancellation()
                return Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
            }
            storeLoads[paywallID] = task
        }
        do {
            let productsByID = try await withPaywallLoadTimeout(seconds: 2) {
                guard !task.isCancelled else { throw CancellationError() }
                return try await task.value
            }
            let missingIDs = productIDs.filter { productsByID[$0] == nil }

            if !missingIDs.isEmpty {
                PremiumLog.warning(
                    .fallback,
                    "Fallback \(paywallID.rawValue): StoreKit products unavailable, using offline price data for: \(missingIDs.joined(separator: ", "))"
                )
            }

            return productsByID
        } catch {
            // Other requests for this placement may still need the shared worker.
            PremiumLog.warning(
                .fallback,
                "Fallback \(paywallID.rawValue): StoreKit products could not be loaded — \(error.localizedDescription); using offline price data"
            )
            return [:]
        }
    }
    
    /// One shared budget for all introductory-offer eligibility checks. A slow
    /// check must not discard StoreKit prices already obtained above.
    private func loadEligibility(
        for products: [String: Product],
        paywallID: PremiumPaywallID
    ) async -> [String: Bool] {
        guard !products.isEmpty, !Task.isCancelled else { return [:] }
        let task: Task<[String: Bool], Error>
        if let pending = eligibilityLoads[paywallID] {
            task = pending
        } else {
            task = Task { @MainActor in
                defer { self.eligibilityLoads[paywallID] = nil }
                var result: [String: Bool] = [:]
                for (id, product) in products {
                    try Task.checkCancellation()
                    if let subscription = product.subscription {
                        result[id] = await subscription.isEligibleForIntroOffer
                    }
                }
                try Task.checkCancellation()
                return result
            }
            eligibilityLoads[paywallID] = task
        }
        do {
            return try await withPaywallLoadTimeout(seconds: 1) {
                guard !task.isCancelled else { throw CancellationError() }
                return try await task.value
            }
        } catch {
            // A cancelled waiter must not discard another request's eligibility.
            return [:]
        }
    }

    private func loadFallbackPaywall(_ paywallType: PremiumPaywallID, fileName: String) -> FallbackPaywall? {
        let source = "\(fileName).json"

        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            PremiumLog.error(
                .fallback,
                "Fallback \(source) not found in the app bundle — check target membership and PremiumConfiguration.fallbackFileName"
            )
            return nil
        }

        guard let data = readFallbackData(at: url, source: source) else { return nil }

        let file: FallbackFile
        do {
            file = try JSONDecoder().decode(FallbackFile.self, from: data)
        } catch {
            let report = JSONDiagnostics.describe(error, in: data)
            PremiumLog.error(.fallback, "Fallback \(source) is invalid — \(report.message)", details: report.fragment)
            return nil
        }

        guard let entry = file.data.results.first(where: { $0.name == paywallType.rawValue }) else {
            let names = file.data.results.map(\.name).joined(separator: ", ")
            PremiumLog.error(
                .fallback,
                "Fallback \(source) has no paywall \"\(paywallType.rawValue)\"; available: \(names.isEmpty ? "none" : names)"
            )
            return nil
        }

        let innerData = Data(entry.json.utf8)
        if let report = JSONDiagnostics.suspiciousCharacters(in: innerData) {
            PremiumLog.warning(
                .fallback,
                "Fallback \(source), paywall \"\(entry.name)\": json \(report.message)",
                details: report.fragment
            )
        }

        do {
            return try JSONDecoder().decode(FallbackPaywall.self, from: innerData)
        } catch {
            let report = JSONDiagnostics.describe(error, in: innerData)
            PremiumLog.error(
                .fallback,
                "Fallback \(source), paywall \"\(entry.name)\": json is invalid — \(report.message)",
                details: report.fragment
            )
            return nil
        }
    }

    private func readFallbackData(at url: URL, source: String) -> Data? {
        do {
            guard let data = try PremiumKitFallbackDecoder31536c10dc83d59e.decrypt(Data(contentsOf: url)) else {
                PremiumLog.error(.fallback, "Fallback \(source) could not be read")
                return nil
            }
            return data
        } catch {
            PremiumLog.error(.fallback, "Fallback \(source) could not be read — \(error.localizedDescription)")
            return nil
        }
    }

    private func skFind(productId: String) -> SKConfig.SKProduct? {
        guard let config = SKConfig.shared else { return nil }

        if let product = config.subscriptionGroups?.flatMap(\.subscriptions).first(where: { $0.productID == productId }) {
            return product
        }
        if let product = config.nonRenewingSubscriptions?.first(where: { $0.productID == productId }) {
            return product
        }
        if let product = config.nonConsumableProducts?.first(where: { $0.productID == productId }) {
            return product
        }
        return nil
    }
    
    private func perPeriodString(price: String, period: SKConfig.SKProduct.Period?) -> String {
            guard let period else { return "$\(price)/\(L10n.Period.oneTime)" }
            return "$\(price)/\(period.localizedOne)"
        }

    private func moneyToDecimal(_ s: String) -> Decimal? {
        let filtered = s.filter { "0123456789.,".contains($0) }
        let normalized = filtered.replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
    }

    private func weeks(in period: SKConfig.SKProduct.Period) -> Decimal {
        switch period.unit {
        case .day:        return Decimal(period.numberOfUnits) / 7
        case .weekOfMonth:return Decimal(period.numberOfUnits)
        case .month:      return Decimal(period.numberOfUnits * 4)
        case .year:       return Decimal(period.numberOfUnits * 52)
        default:          return 1
        }
    }

    private func truncate(_ value: Decimal, scale: Int) -> Decimal {
        var v = value, r = Decimal()
        NSDecimalRound(&r, &v, scale, .down)
        return r
    }

    private func currencySymbol(from price: String) -> String {
        for ch in price {
            if !ch.isNumber && ch != "." && ch != "," && !ch.isWhitespace { return String(ch) }
        }
        return "$"
    }

    private func perWeekString(price: String, period: SKConfig.SKProduct.Period?) -> String {
        guard let period, let priceDec = moneyToDecimal(price) else {
            return L10n.Price.limitedOffer
        }

        let isWeekly = (period.unit == .weekOfMonth && period.numberOfUnits == 1)
                    || (period.unit == .day && period.numberOfUnits == 7)

        let weekly = isWeekly ? priceDec : (priceDec / weeks(in: period))
        let truncated = truncate(weekly, scale: 2)

        let sym = currencySymbol(from: price)
        return L10n.Price.perWeek("\(sym)\(truncated)")
    }
}
