import Foundation
import StoreKit
import Combine

class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    // Kept for reference but disabled to avoid conflict with Superwall
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var currentSubscription: Product?
    
    private let productIDs = ["com.alyai.subscription.yearly"]
    
    init() {
        // Disabled transaction listening as Superwall handles this now.
        /*
        Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await updateCustomerProductStatus()
                }
            }
        }
        
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
        */
    }
    
    @MainActor
    func requestProducts() async {
        // No-op
    }
    
    @MainActor
    func purchase(_ product: Product) async throws {
        // No-op
    }
    
    @MainActor
    func updateCustomerProductStatus() async {
        // No-op
    }
    
    var isSubscribed: Bool {
        !purchasedProductIDs.isEmpty
    }
}
