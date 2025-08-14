//
//  File.swift
//  GStoreKit
//
//  Created by mayong on 2025/8/14.
//

import Foundation
import StoreKit

@available(iOS 15.0, *)
public typealias SKPaymentV2Result = (SKPaymentV2ObjcTransaction?, Error?)

@available(iOS 15.0, *)
open class SKPaymentV2Objc: NSObject {
    @objc public static let shared = SKPaymentV2Objc()
    
    let updatedObserver = SKPaymentV2ObjcObserver()
    
    let currentEntitlementsObserver = SKPaymentV2ObjcObserver()
    
    override private init() {
        super.init()
        observeTransactionUpdates()
        observeTransactionCurrentEntitlements()
    }
    
    @objc public func purchase(
        product: SKPaymentV2ObjcProduct,
        completion: @escaping @Sendable (SKPaymentV2ObjcTransaction?, Error?) -> Void
    ) {
        Task {
            do {
                let purchasedTransaction = try await product.product.purchase().transaction
                await MainActor.run {
                    completion(
                        SKPaymentV2ObjcTransaction(transaction: purchasedTransaction),
                        nil
                    )
                }
            } catch {
                await MainActor.run {
                    completion(nil, error)
                }
            }
        }
    }
    
    @objc public func fetchProducts(
        for identifiers: [String],
        completion: @escaping @Sendable ([SKPaymentV2ObjcProduct]?, Error?) -> Void
    ) {
        Task {
            do {
                let products = try await Product.products(for: identifiers)
                await MainActor.run {
                    completion(
                        products.map(SKPaymentV2ObjcProduct.init),
                        nil
                    )
                }
            } catch {
                await MainActor.run {
                    completion(
                        nil,
                        error
                    )
                }
            }
        }
    }
    
    /// updated.
    @objc public func observeUpdatedTransactions(
        _ action: @escaping @Sendable (SKPaymentV2ObjcTransaction?, Error?) -> Void
    ) {
        Task {
            await updatedObserver.observeUpdatedTransactions {
                action($0.0, $0.1)
            }
        }
    }
    
    /// Observe current entitlements. Restore
    @objc public func observeCurrentEntitlements(
        _ action: @escaping @Sendable (SKPaymentV2ObjcTransaction?, Error?) -> Void
    ) {
        Task {
            await currentEntitlementsObserver.observeUpdatedTransactions {
                action($0.0, $0.1)
            }
        }
    }
    
    private func observeTransactionCurrentEntitlements() {
        Task {
            for await update in Transaction.currentEntitlements {
                switch update {
                case let .verified(transaction):
                    await currentEntitlementsObserver.scheduleTransactionUpdateObserver(
                        result: (
                            transaction: .init(transaction: transaction),
                            error: nil
                        )
                    )
                case let .unverified(transaction, error):
                    await currentEntitlementsObserver.scheduleTransactionUpdateObserver(
                        result: (
                            transaction: .init(transaction: transaction),
                            error: error
                        )
                    )
                }
            }
        }
    }
    
    private func observeTransactionUpdates() {
        Task {
            for await update in Transaction.updates {
                switch update {
                case let .verified(transaction):
                    await updatedObserver.scheduleTransactionUpdateObserver(
                        result: (
                            transaction: .init(transaction: transaction),
                            error: nil
                        )
                    )
                case let .unverified(transaction, error):
                    await updatedObserver.scheduleTransactionUpdateObserver(
                        result: (
                            transaction: .init(transaction: transaction),
                            error: error
                        )
                    )
                }
            }
        }
    }
}
