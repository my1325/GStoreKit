//
//  SKPaymentV2ObjcObserver.swift
//  GStoreKit
//
//  Created by mayong on 2025/8/14.
//

@available(iOS 15.0, *)
actor SKPaymentV2ObjcObserver {
    private(set) var transcationUpdatedObserver: (@Sendable (SKPaymentV2Result) -> Void)?
    
    private(set) var cachedUnhandedTransactions: [SKPaymentV2Result] = []
    
    func observeUpdatedTransactions(
        _ action: @escaping @Sendable (SKPaymentV2Result) -> Void
    ) {
        transcationUpdatedObserver = action
        Task {
            while !cachedUnhandedTransactions.isEmpty {
                let result = cachedUnhandedTransactions.removeFirst()
                await scheduleTransactionUpdateObserver(result: result)
            }
        }
    }
    
    func scheduleTransactionUpdateObserver(result: SKPaymentV2Result) async {
        if let observer = transcationUpdatedObserver {
            await MainActor.run {
                observer(result)
            }
        } else {
            cachedUnhandedTransactions.append(result)
        }
    }
}
