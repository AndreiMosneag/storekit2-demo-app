//
//  PurchaseManager.swift
//  Step10
//
//  Created by Mosenag Andrei on 11/07/23.
//

import Foundation
import StoreKit

// MARK: - PurchaseManager

@MainActor
class PurchaseManager: NSObject, ObservableObject {
    // MARK: Lifecycle

    init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
        super.init()
        self.updates = self.observeTransactionUpdates()
        SKPaymentQueue.default().add(self)
    }

    deinit {
        self.updates?.cancel()
    }

    // MARK: Internal

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    @Published var errorMessage: String = ""
    @Published var showErrorBanner: Bool = false

    func loadProducts() async throws {
        guard !self.productsLoaded else {
            return
        }
        self.products = try await Product.products(for: self.productIds)
        self.productsLoaded = true
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case let .success(.verified(transaction)):
            // Successful purchase
            await transaction.finish()
            await self.updatePurchasedProducts()
        case let .success(.unverified(_, error)):
            self.errorMessage = "Unverified purchase: \(error.localizedDescription)"
            self.showErrorBanner = true
        case .pending:
            self.errorMessage = "Purchase is pending. Please check your payment method or wait for approval."
            self.showErrorBanner = true
        case .userCancelled:
            // Notify user of cancellation
            self.errorMessage = "Cancelled the purchase"
            self.showErrorBanner = true
        @unknown default:
            break
        }
    }

    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else {
                continue
            }

            if transaction.revocationDate == nil {
                self.purchasedProductIDs.insert(transaction.productID)
            } else {
                self.purchasedProductIDs.remove(transaction.productID)
            }
        }

        self.entitlementManager.hasPro = !self.purchasedProductIDs.isEmpty
    }

    // MARK: Private

    private let productIds = ["set_999_1y", "set_099_1M"]

    private let entitlementManager: EntitlementManager
    private var productsLoaded = false
    private var updates: Task<Void, Never>? = nil

    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await verificationResult in Transaction.updates {
                switch verificationResult {
                case let .verified(transaction):
                    if transaction.revocationDate == nil {
                        self.purchasedProductIDs.insert(transaction.productID)
                    } else {
                        self.purchasedProductIDs.remove(transaction.productID)
                    }
                default:
                    continue
                }

                self.entitlementManager.hasPro = !self.purchasedProductIDs.isEmpty
            }
        }
    }
}

// MARK: SKPaymentTransactionObserver

extension PurchaseManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                // Unlock premium features, finish transaction
                break
            case .failed:
                // Handle failure, finish transaction
                break
            case .restored:
                // Restore premium features, finish transaction
                break
            case .deferred, .purchasing:
                break
            @unknown default:
                break
            }
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        // Allow store payment
        return true
    }
}

