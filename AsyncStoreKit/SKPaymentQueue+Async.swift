//
//  SKPaymentQueue+VerifyReceipts.swift
//
//
//  Created by mayong on 2024/1/31.
//

import Foundation
import StoreKit
#if canImport(StoreKitCore)
import StoreKitCore
#endif

public extension SKPaymentQueue {
    
    func restoreCompletedTransactions() async throws -> [SKPaymentTransaction] {
        try await withCheckedThrowingContinuation { continuation in
            transactionObserver.onRestoreCompleted { skQueue in
                continuation.resume(returning: skQueue.transactions)
            }
            
            transactionObserver.onRestoreFailed { skQueue, error in
                continuation.resume(throwing: error)
            }
            
            self.restoreCompletedTransactions()
        }
    }
    
    func purchase(_ productId: String) async throws -> SKPaymentTransaction {
        let payment = SKMutablePayment()
        payment.productIdentifier = productId
        return try await purchase(payment)
    }
    
    func purchase(_ product: SKProduct) async throws -> SKPaymentTransaction {
        try await purchase(SKPayment(product: product))
    }
    
    func purchase(_ payment: SKPayment) async throws -> SKPaymentTransaction {
        try await withCheckedThrowingContinuation { continuation in
            transactionObserver.onUpdated { transactions in
                guard let transaction = transactions.first else {
                    continuation.resume(throwing: SKReceiptError.emptyTransaction)
                    return
                }
                switch transaction.transactionState {
                case .purchased:
                    continuation.resume(returning: transaction)
                case .failed, .restored:
                    continuation.resume(throwing: transaction.error ?? SKReceiptError.illegal)
                case .purchasing, .deferred: break
                default: break
                }
            }
            
            self.add(payment)
        }
    }
}
