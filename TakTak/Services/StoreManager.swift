import StoreKit
import SwiftUI

/// Uygulama içi satın almalar (StoreKit 2).
///
/// App Store Connect > Uygulama > Uygulama İçi Satın Alma bölümünde bu kimliklerle ürünleri oluştur:
/// - `com.damlanur.taktakgame.noads`     Tüketilemez (Non-Consumable): "Reklamsız"
/// - `com.damlanur.taktakgame.coins1000` Tüketilebilir (Consumable): 1.000 para
/// - `com.damlanur.taktakgame.coins3000` Tüketilebilir: 3.000 para
/// - `com.damlanur.taktakgame.coins8000` Tüketilebilir: 8.000 para
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    enum ProductID {
        static let noAds = "com.damlanur.taktakgame.noads"
        static let coins1000 = "com.damlanur.taktakgame.coins1000"
        static let coins3000 = "com.damlanur.taktakgame.coins3000"
        static let coins8000 = "com.damlanur.taktakgame.coins8000"
        static let all = [noAds, coins1000, coins3000, coins8000]

        static func coins(for id: String) -> Int {
            switch id {
            case coins1000: return 1000
            case coins3000: return 3000
            case coins8000: return 8000
            default: return 0
            }
        }
    }

    @Published private(set) var products: [Product] = []
    @Published private(set) var loadFailed = false
    @Published private(set) var purchasing: String?

    /// Satın alma tamamlanınca GameStore'a iletilir (para ekleme, reklamsız açma).
    var onCoins: ((Int) -> Void)?
    var onNoAds: ((Bool) -> Void)?

    private var updatesTask: Task<Void, Never>?

    private init() {}

    @MainActor
    func start() {
        guard updatesTask == nil else { return }
        // Uygulama dışında tamamlanan / ertelenen satın almalar
        updatesTask = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                await self?.handle(result)
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    @MainActor
    func loadProducts() async {
        do {
            let list = try await Product.products(for: ProductID.all)
            products = list.sorted { $0.price < $1.price }
            loadFailed = list.isEmpty
        } catch {
            loadFailed = true
        }
    }

    var noAdsProduct: Product? { products.first { $0.id == ProductID.noAds } }
    var coinProducts: [Product] { products.filter { $0.type == .consumable } }

    enum PurchaseOutcome { case success, cancelled, pending, failed }

    @MainActor
    func purchase(_ product: Product) async -> PurchaseOutcome {
        purchasing = product.id
        defer { purchasing = nil }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(verification)
                return .success
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed
            }
        } catch {
            return .failed
        }
    }

    /// "Satın alımları geri yükle"
    @MainActor
    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    @MainActor
    private func refreshEntitlements() async {
        var hasNoAds = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == ProductID.noAds, t.revocationDate == nil {
                hasNoAds = true
            }
        }
        onNoAds?(hasNoAds)
    }

    @MainActor
    private func handle(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let t) = result else { return }
        if t.productID == ProductID.noAds {
            onNoAds?(t.revocationDate == nil)
        } else {
            let amount = ProductID.coins(for: t.productID)
            if amount > 0, t.revocationDate == nil { onCoins?(amount) }
        }
        await t.finish()
    }
}
