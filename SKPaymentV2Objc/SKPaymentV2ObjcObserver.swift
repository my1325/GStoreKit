//
//  SKPaymentV2ObjcObserver.swift
//  GStoreKit
//
//  Created by mayong on 2025/8/14.
//

@available(iOS 15.0, *)
actor SKPaymentV2ObjcObserver {
    private var transactionUpdatedObserver: (@Sendable (SKPaymentV2Result) -> Void)?
    private var cachedUnhandledTransactions: [SKPaymentV2Result] = []
    
    func observeUpdatedTransactions(
        _ action: @escaping @Sendable (SKPaymentV2Result) -> Void
    ) {
        transactionUpdatedObserver = action
        
        // Process cached transactions
        Task {
            await processCachedTransactions()
        }
    }
    
    func scheduleTransactionUpdateObserver(result: SKPaymentV2Result) async {
        if let observer = transactionUpdatedObserver {
            await MainActor.run {
                observer(result)
            }
        } else {
            cachedUnhandledTransactions.append(result)
        }
    }
    
    private func processCachedTransactions() async {
        while !cachedUnhandledTransactions.isEmpty {
            let result = cachedUnhandledTransactions.removeFirst()
            await scheduleTransactionUpdateObserver(result: result)
        }
    }
}
