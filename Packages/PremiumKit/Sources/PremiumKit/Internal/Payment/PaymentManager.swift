@preconcurrency import ApphudSDK
import StoreKit
import AdServices
import Combine
import UIKit

fileprivate enum Constants {
    static let trialUserDefaultsKey = "TRIAL"
}

@MainActor
internal final class PaymentManager: ObservableObject {
    
    static let shared = PaymentManager()
    
    @Published private(set) var loadedPaywalls: [PremiumPaywallID: PaywallModel] = [:]
    @Published private(set) var isPremium = false
    @Published private(set) var activeProductIds: Set<String> = []
    @Published private(set) var availableProducts: AvailableProducts = .withTrial
    @Published private(set) var isShowingSplash = true
    private var isPremiumChecked = false
    private var isRefreshingSubscription = false
    private var entitlementRevision: UInt64 = 0
    private var entitlementSession: UInt64 = 0
    #if DEBUG
    private var usesLocalStoreKit = false
    private var transactionUpdatesTask: Task<Void, Never>?
    private var entitlementRefreshTask: Task<Void, Never>?
    #endif
    
    var isTrialExpired: Bool {
        isPremiumChecked && UserDefaults.standard.object(forKey: Constants.trialUserDefaultsKey) != nil && !isPremium
    }
    
    private let networkMonitor: NetworMonitoring = NetworMonitoringImpl()
    private let fallbackHelper = FallbackHelper()
    
    private var cancellables: Set<AnyCancellable> = []
    
    private struct RealPaywallResult {
        let model: PaywallModel?
        let paywall: ApphudPaywall
    }

    private var loadRequests: [PremiumPaywallID: UUID] = [:]
    // Keep a cancelled but non-cooperative SDK request until it actually exits.
    private var realLoads: [PremiumPaywallID: Task<RealPaywallResult, Error>] = [:]
    private var loadState: ProductLoadState = .none
    
    private var forceFallback = false
    private var fallbackFileName = "apphud_paywalls_fallback"
    
    private var paywallsApphud: [PremiumPaywallID: ApphudPaywall] = [:]
    
    private init() {
        let noised83845bb5dd499b3 = PremiumKitNoise59444411e5a53e44(seed: 10934490770011559095)
        _ = noised83845bb5dd499b3.digest()
        bind()
    }
    
    //MARK: - public methods
    
    func grantPremium() {
        isPremium = true
    }

    func grantPremium(for id: PremiumPaywallID) {
        let ids = loadedPaywalls[id]?.products.map { $0.id } ?? []
        activeProductIds.formUnion(ids)
    }
    
    ///Вызывается при старте приложения didFinishLaunchingWithOptions
    func start(
        apiKey: String,
        userID: String? = nil,
        forceFallback: Bool = false,
        fallbackFileName: String = "apphud_paywalls_fallback"
    ) {
        self.forceFallback = forceFallback
        self.fallbackFileName = fallbackFileName
        #if DEBUG
        // Local StoreKit must not depend on Apphud's startup/network callback.
        Task { [weak self] in
            await self?.checkPremiumSubscription()
        }
        #endif
        Apphud.start(apiKey: apiKey, userID: userID) { [weak self] _ in
            _Concurrency.Task {
                await self?.checkPremiumSubscription()
                self?.trackASA()
                Apphud.setPaywallsCacheTimeout(60 * 60)
            }
        }
    }
    
    ///Загружает токек пушей в апхуд
    func submitPushToken(_ token: Data) {
        Apphud.submitPushNotificationsToken(token: token, callback: nil)
    }
    
    func logout() {
        Task { await Apphud.logout() }
        isPremiumChecked = false
        entitlementRevision &+= 1
        entitlementSession &+= 1
        #if DEBUG
        entitlementRefreshTask?.cancel()
        entitlementRefreshTask = nil
        #endif
        isPremium = false
        activeProductIds = []
    }
    
    private func setPaywall(_ model: PaywallModel, for id: PremiumPaywallID) {
        loadedPaywalls[id] = model
    }
    
    private func paywall(for id: PremiumPaywallID) -> PaywallModel? {
        loadedPaywalls[id]
    }
    
    ///Вызывается для загрузки пейвола только при старте флоу
    func fetchPaywall(_ id: PremiumPaywallID) async {
        guard !Task.isCancelled else { return }
        let request = UUID()
        loadRequests[id] = request
        loadState = .loading
        var apphudPaywall: ApphudPaywall?
        var failedRealLoad = false

        if !forceFallback {
            let task: Task<RealPaywallResult, Error>
            if let pending = realLoads[id] {
                task = pending
            } else {
                task = Task { @MainActor in
                    defer { self.realLoads[id] = nil }
                    return try await self.loadRealPaywall(id)
                }
                realLoads[id] = task
            }
            do {
                let result = try await withPaywallLoadTimeout(seconds: 5) {
                    guard !task.isCancelled else { throw CancellationError() }
                    return try await task.value
                }
                guard loadRequests[id] == request else { return }
                guard !Task.isCancelled else {
                    loadState = .failed
                    isShowingSplash = false
                    return
                }
                apphudPaywall = result.paywall
                if let model = result.model {
                    publishPaywall(model, apphudPaywall: result.paywall, for: id, source: "Apphud")
                    return
                }
            } catch {
                guard loadRequests[id] == request else { return }
                task.cancel()
                failedRealLoad = true
                guard !Task.isCancelled else {
                    loadState = .failed
                    isShowingSplash = false
                    return
                }
                PremiumLog.warning(
                    .paywall,
                    "Paywall \(id.rawValue): Apphud load failed — \(error) → using fallback \(fallbackFileName).json"
                )
            }
        }

        let model = await fallbackHelper.fallbackToPaywallModel(for: id, fileName: fallbackFileName)
        guard loadRequests[id] == request else { return }
        guard !Task.isCancelled else {
            loadState = .failed
            isShowingSplash = false
            return
        }
        publishPaywall(
            model, apphudPaywall: apphudPaywall, for: id,
            source: "Fallback", failedRealLoad: failedRealLoad
        )
    }

    private func publishPaywall(
        _ model: PaywallModel,
        apphudPaywall: ApphudPaywall?,
        for id: PremiumPaywallID,
        source: String,
        failedRealLoad: Bool = false
    ) {
        paywallsApphud[id] = apphudPaywall
        setPaywall(model, for: id)
        if id.isAvailablePaywall { setAvailableProducts() }
        loadState = failedRealLoad ? .failed : .loaded
        isShowingSplash = false
        logPaywallLoaded(id: id, source: source)
    }

    ///Ивент аналитики показа пейвола
    func paywallShownEvent(_ id: PremiumPaywallID = .main) {
        guard let apphudPaywall = paywallsApphud[id] else {
            PremiumLog.warning(.paywall, "Paywall shown skipped — no Apphud paywall for: \(id.rawValue)")
            return
        }
        
        PremiumLog.info(.paywall, "Paywall shown — \(id.rawValue)")
        Apphud.paywallShown(apphudPaywall)
    }
    
    ///Востановление покупок
    func restorePurchase() async -> Result<Void, PaymentError> {
        let session = entitlementSession
        #if DEBUG
        await checkPremiumSubscription()
        guard session == entitlementSession else { return .failure(.cancelled) }
        if usesLocalStoreKit {
            do {
                try await AppStore.sync()
                guard session == entitlementSession else { return .failure(.cancelled) }
                await checkPremiumSubscription()
                guard session == entitlementSession else { return .failure(.cancelled) }
                return isPremium ? .success(()) : .failure(.restoreNothingToRestore)
            } catch {
                return .failure(PaymentError.from(error))
            }
        }
        #endif
#if targetEnvironment(simulator)
        return .failure(.restoreNothingToRestore)
#else
        let result = await Apphud.restorePurchases()
        guard session == entitlementSession else { return .failure(.cancelled) }
        if let error = result?.error {
            return .failure(PaymentError.from(error))
        }
        
        await checkPremiumSubscription()
        guard session == entitlementSession else { return .failure(.cancelled) }
        if isPremium {
            return .success(())
        } else {
            return .failure(.restoreNothingToRestore)
        }
#endif
    }
    
    func purchase(_ product: ProductModel, from id: PremiumPaywallID) async -> Result<String, PaymentError> {
        #if DEBUG
        // The local StoreKit catalog is independent of Apphud placement availability.
        return await purchaseViaSK2(product, paywallID: id)
        #else
        let session = entitlementSession
        guard
            let apphudPaywall = paywallsApphud[id],
            let ahProduct = apphudPaywall.products.first(where: { $0.productId == product.id })
        else {
            PremiumLog.warning(.purchase, "No Apphud paywall for \(id.rawValue) — purchasing by product id: \(product.id)")
            return await purchaseByID(product, paywallID: id)
        }
        
        PremiumLog.info(.purchase, "Purchase started — \(product.id) from paywall: \(id.rawValue)")
        
        let result = await Apphud.purchase(ahProduct)
        
        if result.success {
            let isTrial = product.isTrial || result.subscription?.status == .trial
            
            guard await applyPurchaseSuccess(product: product, paywallID: id, isTrial: isTrial, session: session) else {
                return .failure(.cancelled)
            }
            
            return .success(product.id)
        }
        
        if let error = result.error {
            return .failure(PaymentError.from(error))
        }
        
        return .failure(paymentError(from: result))
#endif
    }
    
    /// Ошибка покупки, когда Apphud не вернул error: отложенная транзакция (Ask to Buy) — это .pending
    private func paymentError(from result: ApphudPurchaseResult) -> PaymentError {
        if result.transaction?.transactionState == .deferred {
            return .pending
        }
        
        return .unknown
    }
    
    /// Общая обработка успешной покупки для всех способов оплаты
    private func applyPurchaseSuccess(
        product: ProductModel,
        paywallID: PremiumPaywallID,
        isTrial: Bool,
        session: UInt64
    ) async -> Bool {
        guard session == entitlementSession else { return false }
        #if DEBUG
        if usesLocalStoreKit {
            await checkPremiumSubscription()
            // Logout cancels the shared scan, not its purchase waiter.
            guard session == entitlementSession else { return false }
        } else {
            isPremium = true
            activeProductIds.insert(product.id)
        }
        #else
        isPremium = true
        activeProductIds.insert(product.id)
        #endif
        
        if isTrial {
            saveTrialStartDate()
        }
        
        addConsumableTokens(from: product, paywallID: paywallID)
        return true
    }
    
    /// Фоллбэк-покупка по product id из фолбэк-модели, когда пейвол Apphud не загрузился
    private func purchaseByID(_ product: ProductModel, paywallID: PremiumPaywallID) async -> Result<String, PaymentError> {
        let session = entitlementSession
        let result: ApphudPurchaseResult = await withCheckedContinuation { continuation in
            Apphud.purchase(product.id) { result in
                continuation.resume(returning: result)
            }
        }
        
        if result.success {
            ///В фолбэке ProductModel.isTrial недостоверен — берём статус из ответа Apphud
            let isTrial = product.isTrial || result.subscription?.status == .trial
            
            guard await applyPurchaseSuccess(product: product, paywallID: paywallID, isTrial: isTrial, session: session)
            else {
                return .failure(.cancelled)
            }
            
            PremiumLog.info(.purchase, "Purchased by product id — \(product.id)")
            return .success(product.id)
        }
        
        if let error = result.error {
            return .failure(PaymentError.from(error))
        }
        
        return .failure(paymentError(from: result))
    }
    
    #if DEBUG
    private func purchaseViaSK2(_ product: ProductModel, paywallID: PremiumPaywallID) async -> Result<
        String, PaymentError
    > {
        let session = entitlementSession
        do {
            guard let sk2Product = try await Product.products(for: [product.id]).first else {
                return .failure(.productNotAvailable)
            }
            let result = try await sk2Product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    guard session == entitlementSession else {
                        return .failure(.cancelled)
                    }
                    guard transaction.productID == product.id else {
                        return .failure(.verificationFailed)
                    }
                    if transaction.environment == .xcode {
                        usesLocalStoreKit = true
                    }
                    guard
                        await applyPurchaseSuccess(
                            product: product, paywallID: paywallID, isTrial: product.isTrial, session: session
                        )
                    else {
                        return .failure(.cancelled)
                    }
                    if transaction.environment == .xcode {
                        await transaction.finish()
                    }
                    PremiumLog.info(.purchase, "Debug: purchased via SK2 — \(product.id)")
                    return .success(product.id)
                case .unverified:
                    return .failure(.verificationFailed)
                }
            case .userCancelled:
                return .failure(.cancelled)
            case .pending:
                return .failure(.pending)
            @unknown default:
                return .failure(.unknown)
            }
        } catch {
            return .failure(PaymentError.from(error))
        }
    }
    #endif

    
    //MARK: - private methods
    private func loadRealPaywall(_ id: PremiumPaywallID) async throws -> RealPaywallResult {

        guard let placement = await Apphud.placement(id.rawValue) else {
            throw PaywallLoadError.placementNotFound(id.rawValue)
        }
        guard let paywall = placement.paywall else {
            throw PaywallLoadError.paywallNotAttached(id.rawValue)
        }

        try Task.checkCancellation()
        if paywall.shouldShowFallback {
            return RealPaywallResult(model: nil, paywall: paywall)
        }

        let model: PaywallModel
        if paywall.products.isEmpty {
            PremiumLog.warning(.paywall, "Paywall \(id.rawValue): Apphud paywall \"\(paywall.identifier)\" has no products")
        }

        for ahProduct in paywall.products {
            try Task.checkCancellation()
            let product: Product?
            do {
                product = try await ahProduct.product()
                try Task.checkCancellation()
            } catch {
                throw PaywallLoadError.productNotLoaded(ahProduct.productId, reason: error.localizedDescription)
            }
            guard product != nil else {
                throw PaywallLoadError.productNotLoaded(ahProduct.productId, reason: nil)
            }
        }

        let response = paywall.paywallResponse
        if let response, let responseProducts = response.products, !responseProducts.isEmpty {
            logProductMismatch(
                id: id,
                jsonProductIDs: responseProducts.map(\.id),
                apphudProductIDs: paywall.products.map(\.productId)
            )
            var productModels: [ProductModel] = []

            for responseProduct in responseProducts {
                guard let ahProduct = paywall.products.first(
                    where: { $0.productId == responseProduct.id }
                ) else { continue }

                try Task.checkCancellation()
                let isTrial = await ahProduct.isTrail()
                try Task.checkCancellation()
                let isLifetime = await ahProduct.nonConsumable
                try Task.checkCancellation()
                let pricePerPeriod = await ahProduct.getPricePerPeriod()
                try Task.checkCancellation()
                var pricePerWeek = await ahProduct.getPricePerWeek()
                try Task.checkCancellation()
                let trialDuration = await ahProduct.getTrialDuration()
                try Task.checkCancellation()
                let subscriptionDuration = await ahProduct.getSubscriptionDuration()
                try Task.checkCancellation()

                if isLifetime {
                    let configPeriodly = L10n.resolve(responseProduct.periodly)
                    if !configPeriodly.isEmpty { pricePerWeek = configPeriodly }
                }

                let productModel = ProductModel(
                    id: responseProduct.id,
                    title: L10n.resolve(responseProduct.title),
                    subtitle: L10n.resolveOptional(responseProduct.subtitle),
                    nonTrialSubtitle: L10n.resolveOptional(responseProduct.nonTrialSubtitle),
                    message: L10n.resolveOptional(responseProduct.message),
                    periodly: L10n.resolve(responseProduct.periodly),
                    pricePerPeriod: pricePerPeriod,
                    pricePerWeek: pricePerWeek,
                    isTrial: isTrial,
                    isLifetime: isLifetime,
                    consumable: responseProduct.consumable,
                    consumableUnit: responseProduct.consumableUnit,
                    trialDuration: trialDuration,
                    subscriptionDuration: subscriptionDuration
                )
                productModels.append(productModel)
            }

            if productModels.isEmpty {
                PremiumLog.error(.paywall, "Paywall \(id.rawValue): none of the JSON products exist in the Apphud paywall")
            }

            model = PaywallModel(
                id: id,
                response: response,
                products: productModels
            )
        } else {
            let reason = response == nil ? "JSON is unusable (see the previous log)" : "JSON has no products"
            PremiumLog.warning(
                .paywall,
                "Paywall \(id.rawValue): \(reason) — showing Apphud products with placeholder texts"
            )
            var mock = PaywallModel(id: id)
            var productModels: [ProductModel] = []

            for (index, ahProduct) in paywall.products.enumerated() {
                try Task.checkCancellation()
                let isTrial = await ahProduct.isTrail()
                try Task.checkCancellation()
                let isLifetime = await ahProduct.nonConsumable
                try Task.checkCancellation()
                let pricePerPeriod = await ahProduct.getPricePerPeriod()
                try Task.checkCancellation()
                var pricePerWeek = await ahProduct.getPricePerWeek()
                try Task.checkCancellation()
                let trialDuration = await ahProduct.getTrialDuration()
                try Task.checkCancellation()
                let subscriptionDuration = await ahProduct.getSubscriptionDuration()
                try Task.checkCancellation()

                let mockProduct = index < mock.products.count ? mock.products[index] : nil

                if isLifetime, let configPeriodly = mockProduct?.periodly, !configPeriodly.isEmpty {
                    pricePerWeek = L10n.resolve(configPeriodly)
                }

                productModels.append(ProductModel(
                    id: ahProduct.productId,
                    title: mockProduct?.title ?? ahProduct.productId,
                    subtitle: mockProduct?.subtitle,
                    nonTrialSubtitle: mockProduct?.nonTrialSubtitle,
                    message: mockProduct?.message,
                    periodly: mockProduct?.periodly ?? "",
                    pricePerPeriod: pricePerPeriod,
                    pricePerWeek: pricePerWeek,
                    isTrial: isTrial,
                    isLifetime: isLifetime,
                    consumable: mockProduct?.consumable,
                    consumableUnit: mockProduct?.consumableUnit,
                    trialDuration: trialDuration,
                    subscriptionDuration: subscriptionDuration
                ))
            }

            mock.products = productModels
            model = mock
        }

        try Task.checkCancellation()
        return RealPaywallResult(model: model, paywall: paywall)
    }

    
    private func setAvailableProducts() {
        let products = (loadedPaywalls[.main] ?? loadedPaywalls[.onboarding])?.products ?? []

        if products.count > 1 {
            availableProducts = .bothProducts
            return
        }

        if products.first?.isTrial == true {
            availableProducts = .withTrial
        } else {
            availableProducts = .noTrial
        }
    }

    
    private func bind() {
        #if DEBUG
        transactionUpdatesTask = Task { [weak self] in
            for await update in StoreKit.Transaction.updates {
                guard let self else { return }
                guard case .verified(let transaction) = update,
                    transaction.environment == .xcode
                else { continue }
                self.usesLocalStoreKit = true
                await self.checkPremiumSubscription()
                await transaction.finish()
            }
        }
        #endif
        NotificationCenter.default.publisher(for: Apphud.didUpdateNotification())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, self.isPremiumChecked else { return }
                Task { await self.checkPremiumSubscription() }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshSubscriptionStatus()
            }
            .store(in: &cancellables)

        // Re-evaluate expiry during long foreground sessions using the selected authority.
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.isPremium, UIApplication.shared.applicationState == .active else { return }
                self.refreshSubscriptionStatus()
            }
            .store(in: &cancellables)

        networkMonitor.isConnectedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                guard let self, isConnected else { return }

                Task { @MainActor in
                    guard self.loadState == .failed else { return }
                    let failedID = self.loadedPaywalls.first(where: { $0.key.isAvailablePaywall })?.key ?? .main
                    await self.fetchPaywall(failedID)
                }
            }
            .store(in: &cancellables)
    }


    
    private func trackASA() {
        _Concurrency.Task {
            if let asaToken = try? AAAttribution.attributionToken() {
                Apphud.setAttribution(data: nil,
                                      from: .appleAdsAttribution,
                                      identifer: asaToken,
                                      callback: nil)
            }
        }
    }
    
    private func refreshSubscriptionStatus() {
        guard isPremiumChecked else { return }
        #if DEBUG
        if usesLocalStoreKit {
            Task { await self.checkPremiumSubscription() }
            return
        }
        #endif
        // Only Apphud refreshes depend on the outstanding Apphud network request.
        guard !isRefreshingSubscription else { return }
        isRefreshingSubscription = true
        Apphud.refreshUserData { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.isRefreshingSubscription = false
                guard self.isPremiumChecked else { return }
                await self.checkPremiumSubscription()
            }
        }
    }

    private func checkPremiumSubscription() async {
        entitlementRevision &+= 1
        #if DEBUG
        if let entitlementRefreshTask {
            await entitlementRefreshTask.value
            return
        }
        let refresh = Task { [weak self] in
            guard let self else { return }
            var revision: UInt64
            repeat {
                revision = self.entitlementRevision
                await self.rebuildPremiumSubscription(revision: revision)
            } while !Task.isCancelled && revision != self.entitlementRevision
            if !Task.isCancelled {
                self.entitlementRefreshTask = nil
            }
        }
        entitlementRefreshTask = refresh
        // All callers, including purchase/restore, wait until the latest scan is applied.
        await refresh.value
        #else
        await rebuildPremiumSubscription(revision: entitlementRevision)
        #endif
    }

    private func rebuildPremiumSubscription(revision: UInt64) async {
        #if DEBUG
        var localEntitlements: [LocalStoreKitEntitlementSnapshot.Entitlement] = []
        var foundLocalStoreKit = usesLocalStoreKit
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                transaction.environment == .xcode
            else { continue }
            foundLocalStoreKit = true
            localEntitlements.append(.init(verifiedTransaction: transaction))
        }
        if !foundLocalStoreKit {
            // Expired/refunded history still identifies the local authority after relaunch.
            // Its IDs are never granted; only currentEntitlements above can grant access.
            for await result in StoreKit.Transaction.all {
                guard case .verified(let transaction) = result,
                    transaction.environment == .xcode
                else { continue }
                foundLocalStoreKit = true
                break
            }
        }
        // A newer purchase/update/scan (or logout) invalidates an older suspended scan.
        guard !Task.isCancelled, revision == entitlementRevision else { return }
        usesLocalStoreKit = foundLocalStoreKit
        let localSnapshot =
            foundLocalStoreKit
            ? LocalStoreKitEntitlementSnapshot(entitlements: localEntitlements) : nil
        let snapshot = PremiumEntitlementSnapshot(
            subscriptions: Apphud.subscriptions() ?? [],
            purchases: Apphud.nonRenewingPurchases() ?? [],
            localStoreKit: localSnapshot
        )
        #else
        guard revision == entitlementRevision else { return }
        let snapshot = PremiumEntitlementSnapshot(
            subscriptions: Apphud.subscriptions() ?? [],
            purchases: Apphud.nonRenewingPurchases() ?? []
        )
        #endif
        activeProductIds = snapshot.activeProductIDs
        isPremium = snapshot.isPremium
        isPremiumChecked = true
        #if DEBUG
        if !usesLocalStoreKit {
            checkAndUpdateSubscriptionTokens()
        }
        #else
        checkAndUpdateSubscriptionTokens()
        #endif
    }
    
    private func checkAndUpdateSubscriptionTokens() {
        guard let subscription = Apphud.subscriptions()?.first(where: { $0.isActive() }) else {
            TokenStorage.shared.resetSubscriptionTokens()
            TokenStorage.shared.lastKnownExpiresAt = nil
            TokenStorage.shared.lastSubscriptionProductId = nil
            return
        }
        
        let currentExpiresAt = subscription.expiresDate
        let lastExpiresAt = TokenStorage.shared.lastKnownExpiresAt
        let lastProductId = TokenStorage.shared.lastSubscriptionProductId
        
        let isNewPeriod = lastExpiresAt == nil || currentExpiresAt > lastExpiresAt!
        let isProductChanged = lastProductId != subscription.productId
        
        if isNewPeriod || isProductChanged {
            let storedAmount = TokenStorage.shared.lastSubscriptionTokenAmount
            if storedAmount > 0 {
                TokenStorage.shared.setSubscriptionTokens(storedAmount)
            }
            
            TokenStorage.shared.lastKnownExpiresAt = currentExpiresAt
            TokenStorage.shared.lastSubscriptionProductId = subscription.productId
        }
    }
    
    private func logProductMismatch(id: PremiumPaywallID, jsonProductIDs: [String], apphudProductIDs: [String]) {
        let notInApphud = jsonProductIDs.filter { !apphudProductIDs.contains($0) }
        let notInJSON = apphudProductIDs.filter { !jsonProductIDs.contains($0) }

        if !notInApphud.isEmpty {
            PremiumLog.warning(
                .paywall,
                "Paywall \(id.rawValue): JSON products missing in the Apphud paywall are skipped: \(notInApphud.joined(separator: ", "))"
            )
        }
        if !notInJSON.isEmpty {
            PremiumLog.warning(
                .paywall,
                "Paywall \(id.rawValue): Apphud products missing in JSON are not shown: \(notInJSON.joined(separator: ", "))"
            )
        }
    }

    private func logPaywallLoaded(id: PremiumPaywallID, source: String) {
        let config = paywall(for: id)?.configuration
        PremiumLog.info(.paywall, "Paywall \(id.rawValue) loaded — source: \(source), configuration: \(config?.rawValue ?? "none")")
    }
    
    private func saveTrialStartDate() {
        UserDefaults.standard.set(Date(), forKey: Constants.trialUserDefaultsKey)
    }
    
    private func addConsumableTokens(from product: ProductModel, paywallID: PremiumPaywallID) {
        guard let tokens = product.consumable, tokens > 0 else { return }
        
        if paywallID == .consumable {
            TokenStorage.shared.addPurchased(tokens)
        } else {
            TokenStorage.shared.setSubscriptionTokens(tokens)
            TokenStorage.shared.lastSubscriptionTokenAmount = tokens
            if let subscription = Apphud.subscriptions()?.first(where: { $0.isActive() }) {
                TokenStorage.shared.lastKnownExpiresAt = subscription.expiresDate
                TokenStorage.shared.lastSubscriptionProductId = product.id
            }
        }
    }
}
