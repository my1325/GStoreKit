//
//  SKPaymentQueue+VerifyReceipts.swift
//  
//
//  Created by mayong on 2024/1/31.
//

import Foundation
import StoreKit
#if canImport(SKCore)
import SKCore
#endif

public extension SKPaymentQueue {
    func verifyReceipt(_ transaction: SKPaymentTransaction, excludeOldTransaction: Bool = false) async throws {
        #if DEBUG
            let verifyReceiptURLString = "https://sandbox.itunes.apple.com/verifyReceipt"
        #else
            let verifyReceiptURLString = "https://buy.itunes.apple.com/verifyReceipt"
        #endif
        let url = URL(string: verifyReceiptURLString)!
        do {
            let receiptURL = Bundle.main.appStoreReceiptURL
            let receiptData = try Data(contentsOf: receiptURL!, options: [])
            let base64 = receiptData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            let json = try JSONSerialization.data(withJSONObject: [
                    "receipt-data": base64,
                    "exclude-old-transactions": excludeOldTransaction
                ], options: [])

            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = json
            
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as! HTTPURLResponse
            guard 200 ..< 300 ~= httpResponse.statusCode else {
                throw SKReceiptError.nonHTTPResponse(response: httpResponse)
            }
                
            let responseJSON = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            try verificationResult(for: transaction, response: responseJSON)
        } catch {
            if let receiptError = error as? SKReceiptError {
                throw receiptError
            } else {
                throw SKReceiptError.underlying(error: error)
            }
        }
    }

    private func verificationResult(for transaction: SKPaymentTransaction, response: Any) throws {
        let json = response as! [String: AnyObject]
        let state = json["status"] as! Int
        guard state == 0 else {
            throw SKReceiptError.invalid(code: state)
        }
        
        let receipt = json["receipt"]!
        let inApp = receipt["in_app"] as! [[String: Any]]
        
        let containCondition = { (element: [String: Any]) in
            let productId = element["product_id"] as! String
            return productId == transaction.payment.productIdentifier
        }
        
        if !inApp.contains(where: containCondition) {
            throw SKReceiptError.illegal
        }
    }
    
    func restoreCompletedTransactions() async throws -> [SKPaymentTransaction] {
        try await withCheckedThrowingContinuation { continuation in
            var target: NSObject? = NSObject()
            
            transactionObserver.add(target!, restoreCompletedTransactionsFailedWithErrorAction: { _, error in
                continuation.resume(throwing: error)
                target = nil
            })
            
            transactionObserver.add(target!, paymentQueueRestoreCompletedTransactionsFinishedAction: { paymentQueue in
                continuation.resume(returning: paymentQueue.transactions)
                target = nil
            })
            
            self.restoreCompletedTransactions()
        }
    }
    
    func purchase(_ product: SKProduct, shouldVerify: Bool = false) async throws -> [SKPaymentTransaction] {
        let transactions = try await withCheckedThrowingContinuation { continuation in
            var target: NSObject? = NSObject()
            transactionObserver.add(target!, updatedTransactionAction: { transactions in
                continuation.resume(returning: transactions)
            })
        }
        
        guard shouldVerify else { return transactions }
        
        for transaction in transactions {
            guard transaction.transactionState == .purchased else { continue }
            try await verifyReceipt(transaction)
        }
        return transactions
    }
}
