//
//  CSKPaymentTransactionObserver.swift
//  CombineStoreKit
//
//  Created by mayong on 2023/12/8.
//

import Foundation
import Combine
import StoreKit

public class CSKPaymentTransactionObserver {
    
    static let shared = CSKPaymentTransactionObserver()
    
    private init() {
        SKPaymentQueue.default().add(observer)
    }
    
    deinit {
        SKPaymentQueue.default().remove(observer)
    }
    
    let observer = Observer()
    
    class Observer: NSObject, SKPaymentTransactionObserver {
        
        let updatedTransactionSubject = PassthroughSubject<SKPaymentTransaction, Never>()
        let removedTransactionSubject = PassthroughSubject<SKPaymentTransaction, Never>()
        let restoreCompletedTransactionsFailedWithErrorSubject = PassthroughSubject<(SKPaymentQueue, Error), Never>()
        let paymentQueueRestoreCompletedTransactionsFinishedSubject = PassthroughSubject<SKPaymentQueue, Never>()
        let updatedDownloadSubject = PassthroughSubject<SKDownload, Never>()
        
        public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
            transactions.forEach({ transaction in
                updatedTransactionSubject.send(transaction)
            })
        }
        
        public func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
            transactions.forEach({ transaction in
                removedTransactionSubject.send(transaction)
            })
        }
        
        public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
            restoreCompletedTransactionsFailedWithErrorSubject.send((queue, error))
        }
        
        public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
            paymentQueueRestoreCompletedTransactionsFinishedSubject.send(queue)
        }
        
        public func paymentQueue(_ queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload]) {
            downloads.forEach({ download in
                updatedDownloadSubject.send(download)
            })
        }
        
    }
    
    public var csk_updatedTransaction: AnyPublisher<SKPaymentTransaction, Never> {
        observer.updatedTransactionSubject.eraseToAnyPublisher()
    }
    
    var csk_removedTransaction: AnyPublisher<SKPaymentTransaction, Never> {
        observer.removedTransactionSubject.eraseToAnyPublisher()
    }
    
    var csk_restoreCompletedTransactionsFailedWithError: AnyPublisher<(SKPaymentQueue, Error), Never> {
        observer.restoreCompletedTransactionsFailedWithErrorSubject.eraseToAnyPublisher()
    }
    
    var csk_paymentQueueRestoreCompletedTransactionsFinished: AnyPublisher<SKPaymentQueue, Never> {
        observer.paymentQueueRestoreCompletedTransactionsFinishedSubject.eraseToAnyPublisher()
    }
    
    var csk_updatedDownload: AnyPublisher<SKDownload, Never> {
        observer.updatedDownloadSubject.eraseToAnyPublisher()
    }
}
