import Foundation
import StoreKit

enum ProductID {
    static let singleProgram = "com.gymgyme.program.single"
    static let pocketPTMonthly = "com.gymgyme.pocketpt.monthly"
}

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    @Published var products: [Product] = []
    @Published var purchasedSubscriptions: Set<String> = []
    @Published var programCredits: Int = 0

    private var updateListenerTask: Task<Void, Never>?

    var isPocketPTActive: Bool {
        purchasedSubscriptions.contains(ProductID.pocketPTMonthly)
    }

    var canCreateAIProgram: Bool {
        isPocketPTActive || programCredits > 0
    }

    var pocketPTProduct: Product? {
        products.first { $0.id == ProductID.pocketPTMonthly }
    }

    var singleProgramProduct: Product? {
        products.first { $0.id == ProductID.singleProgram }
    }

    private init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
        Task { await updatePurchaseStatus() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let ids: Set<String> = [ProductID.singleProgram, ProductID.pocketPTMonthly]
            products = try await Product.products(for: ids)
        } catch {
            // products will remain empty, UI will handle gracefully
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await processTransaction(transaction)
            await transaction.finish()
            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        try? await AppStore.sync()
        await updatePurchaseStatus()
    }

    // MARK: - Transaction Processing

    private func processTransaction(_ transaction: Transaction) async {
        if transaction.productID == ProductID.pocketPTMonthly {
            purchasedSubscriptions.insert(transaction.productID)
            // pocket PT includes unlimited programs
            UserDefaults.standard.set(true, forKey: "isPremium")
        } else if transaction.productID == ProductID.singleProgram {
            programCredits += 1
            let stored = UserDefaults.standard.integer(forKey: "programCredits")
            UserDefaults.standard.set(stored + 1, forKey: "programCredits")
        }
    }

    // MARK: - Update Status

    func updatePurchaseStatus() async {
        var activeSubs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }

            if transaction.productID == ProductID.pocketPTMonthly {
                if transaction.revocationDate == nil {
                    activeSubs.insert(transaction.productID)
                }
            }
        }

        purchasedSubscriptions = activeSubs
        programCredits = UserDefaults.standard.integer(forKey: "programCredits")

        let isActive = !activeSubs.isEmpty
        UserDefaults.standard.set(isActive, forKey: "isPremium")
    }

    func useProgramCredit() {
        guard programCredits > 0 else { return }
        programCredits -= 1
        UserDefaults.standard.set(programCredits, forKey: "programCredits")
    }

    // MARK: - Transaction Listener

    private nonisolated func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await StoreManager.shared.updatePurchaseStatus()
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
