//
//  ContentView.swift
//  Shared
//
//  Created by Mosenag Andrei on 11/07/23.
//

import StoreKit
import SwiftUI
import IOSMidnightSubscription

struct ContentView: View {
    
    // MARK: Private

    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var purchaseManager: PurchaseManager
    
    // MARK: Internal

    var body: some View {
        VStack(spacing: 20) {
            if entitlementManager.hasPro {
                Text("Thank you for purchasing pro!")
            } else {
                Text("Products")
                ForEach(purchaseManager.products) { product in
                    Button {
                        _ = Task<Void, Never> {
                            do {
                                try await purchaseManager.purchase(product)
                            } catch {
                                print(error)
                            }
                        }
                    } label: {
                        Text("\(product.displayPrice) - \(product.displayName)")
                            .foregroundColor(.white)
                            .padding()
                            .background(.blue)
                            .clipShape(Capsule())
                    }
                }

                Button {
                    _ = Task<Void, Never> {
                        do {
                            try await AppStore.sync()
                        } catch {
                            print(error)
                        }
                    }
                } label: {
                    Text("Restore Purchases")
                }
            }
        }.task {
            _ = Task<Void, Never> {
                do {
                    try await purchaseManager.loadProducts()
                } catch {
                    print(error)
                }
            }
        }
        .alert(purchaseManager.errorMessage, isPresented: $purchaseManager.showErrorBanner, presenting: purchaseManager.errorMessage) { _ in
            Button("OK") {
                purchaseManager.showErrorBanner = false
            }
        }
    }


}
