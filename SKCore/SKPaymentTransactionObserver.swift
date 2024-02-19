//
//  SKPaymentTransactionObserver.swift
//
//
//  Created by mayong on 2024/1/30.
//

import Foundation
import StoreKit

struct SKObserverTransactionAction {
    typealias Observer = SKPaymentTransactionObserverProxy.Observer
    let updatedTransactionAction: Observer.PaymentTransactionAction
    let removedTransactionAction: Observer.PaymentTransactionAction
    let restoreCompletedTransactionsFailedWithErrorAction: Observer.PaymentQueueWithErrorAction
    let paymentQueueRestoreCompletedTransactionsFinishedAction: Observer.PaymentQueueAction
    let updatedDownloadAction: Observer.DownloadAction
    
    weak var target: AnyObject?
    
    init(
        target: AnyObject,
        updatedTransactionAction: @escaping Observer.PaymentTransactionAction = { _ in },
        removedTransactionAction: @escaping Observer.PaymentTransactionAction = { _ in },
        restoreCompletedTransactionsFailedWithErrorAction: @escaping Observer.PaymentQueueWithErrorAction = { _, _ in },
        paymentQueueRestoreCompletedTransactionsFinishedAction: @escaping Observer.PaymentQueueAction = { _ in },
        updatedDownloadAction: @escaping Observer.DownloadAction = { _ in }
    ) {
        self.target = target
        self.updatedTransactionAction = updatedTransactionAction
        self.removedTransactionAction = removedTransactionAction
        self.restoreCompletedTransactionsFailedWithErrorAction = restoreCompletedTransactionsFailedWithErrorAction
        self.paymentQueueRestoreCompletedTransactionsFinishedAction = paymentQueueRestoreCompletedTransactionsFinishedAction
        self.updatedDownloadAction = updatedDownloadAction
    }
    
    func scheduledUpdatedTransactionAction(_ transactions: [SKPaymentTransaction]) {
        guard target != nil else { return }
        updatedTransactionAction(transactions)
    }
    
    func scheduledRemovedTransactionAction(_ transactions: [SKPaymentTransaction]) {
        guard target != nil else { return }
        removedTransactionAction(transactions)
    }
    
    func scheduledUpdatedDownloadAction(_ downloads: [SKDownload]) {
        guard target != nil else { return }
        updatedDownloadAction(downloads)
    }
    
    func scheduledRestoreCompletedTransactionsFailedWithErrorAction(_ paymentQueue: SKPaymentQueue, _ error: Error) {
        guard target != nil else { return }
        restoreCompletedTransactionsFailedWithErrorAction(paymentQueue, error)
    }
    
    func scheduledPaymentQueueRestoreCompletedTransactionsFinishedAction(_ paymentQueue: SKPaymentQueue) {
        guard target != nil else { return }
        paymentQueueRestoreCompletedTransactionsFinishedAction(paymentQueue)
    }
}

open class SKPaymentTransactionObserverProxy {
    private lazy var observer: Observer = Observer(
        updatedTransactionAction: updatedTransactionAction,
                                                   removedTransactionAction: removedTransactionAction,
                                                   restoreCompletedTransactionsFailedWithErrorAction: restoreCompletedTransactionsFailedWithErrorAction,
                                                   paymentQueueRestoreCompletedTransactionsFinishedAction: paymentQueueRestoreCompletedTransactionsFinishedAction,
                                                   updatedDownloadAction: updatedDownloadAction
    )
    
    init() {
        _ = observer
    }
    
    private var updatedTransactionActions: [SKObserverTransactionAction] = []
    
    private var removedTransactionActions: [SKObserverTransactionAction] = []
    
    private var restoreCompletedTransactionsFailedWithErrorActions: [SKObserverTransactionAction] = []
    
    private var paymentQueueRestoreCompletedTransactionsFinishedActions: [SKObserverTransactionAction] = []
    
    private var updatedDownloadActions: [SKObserverTransactionAction] = []
    
    public static let shared = SKPaymentTransactionObserverProxy()
    
    func updatedTransactionAction(_ transactions: [SKPaymentTransaction]) {
        prepareActions(&updatedTransactionActions) {
            $0.scheduledUpdatedTransactionAction(transactions)
        }
    }
    
    func removedTransactionAction(_ transactions: [SKPaymentTransaction]) {
        prepareActions(&removedTransactionActions) {
            $0.scheduledRemovedTransactionAction(transactions)
        }
    }
    
    func restoreCompletedTransactionsFailedWithErrorAction(_ paymentQueue: SKPaymentQueue, _ error: Error) {
        prepareActions(&restoreCompletedTransactionsFailedWithErrorActions) {
            $0.scheduledRestoreCompletedTransactionsFailedWithErrorAction(paymentQueue, error)
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinishedAction(_ paymentQueue: SKPaymentQueue) {
        prepareActions(&paymentQueueRestoreCompletedTransactionsFinishedActions) {
            $0.scheduledPaymentQueueRestoreCompletedTransactionsFinishedAction(paymentQueue)
        }
    }
    
    func updatedDownloadAction(_ downloads: [SKDownload]) {
        prepareActions(&updatedDownloadActions) {
            $0.scheduledUpdatedDownloadAction(downloads)
        }
    }
    
    func prepareActions(_ actions: inout [SKObserverTransactionAction], doAction: (SKObserverTransactionAction) -> Void) {
        var needRemoveIndexSet: Set<Int> = []
        for index in 0 ..< actions.count {
            let action = actions[index]
            guard action.target != nil else {
                needRemoveIndexSet.insert(index)
                continue
            }
            doAction(action)
        }
        
        while let index = needRemoveIndexSet.popFirst() {
            actions.remove(at: index)
        }
    }
    
    public func add(_ target: AnyObject, updatedTransactionAction: @escaping Observer.PaymentTransactionAction) {
        updatedTransactionActions.append(.init(target: target, updatedTransactionAction: updatedTransactionAction))
    }
    
    public func add(_ target: AnyObject, removedTransactionAction: @escaping Observer.PaymentTransactionAction) {
        updatedTransactionActions.append(.init(target: target, removedTransactionAction: removedTransactionAction))
    }
    
    public func add(_ target: AnyObject, restoreCompletedTransactionsFailedWithErrorAction: @escaping Observer.PaymentQueueWithErrorAction) {
        updatedTransactionActions.append(.init(target: target, restoreCompletedTransactionsFailedWithErrorAction: restoreCompletedTransactionsFailedWithErrorAction))
    }
    
    public func add(_ target: AnyObject, paymentQueueRestoreCompletedTransactionsFinishedAction: @escaping Observer.PaymentQueueAction) {
        updatedTransactionActions.append(.init(target: target, paymentQueueRestoreCompletedTransactionsFinishedAction: paymentQueueRestoreCompletedTransactionsFinishedAction))
    }
    
    public func add(_ target: AnyObject, updatedDownloadAction: @escaping Observer.DownloadAction) {
        updatedTransactionActions.append(.init(target: target, updatedDownloadAction: updatedDownloadAction))
    }
    
    public class Observer: NSObject, SKPaymentTransactionObserver {
        public typealias PaymentTransactionAction = ([SKPaymentTransaction]) -> Void
        public typealias PaymentQueueWithErrorAction = (SKPaymentQueue, Error) -> Void
        public typealias PaymentQueueAction = (SKPaymentQueue) -> Void
        public typealias DownloadAction = ([SKDownload]) -> Void
        
        let updatedTransactionAction: PaymentTransactionAction
        let removedTransactionAction: PaymentTransactionAction
        let restoreCompletedTransactionsFailedWithErrorAction: PaymentQueueWithErrorAction
        let paymentQueueRestoreCompletedTransactionsFinishedAction: PaymentQueueAction
        let updatedDownloadAction: DownloadAction
        
        init(
            updatedTransactionAction: @escaping PaymentTransactionAction,
            removedTransactionAction: @escaping PaymentTransactionAction,
            restoreCompletedTransactionsFailedWithErrorAction: @escaping PaymentQueueWithErrorAction,
            paymentQueueRestoreCompletedTransactionsFinishedAction: @escaping PaymentQueueAction,
            updatedDownloadAction: @escaping DownloadAction
        ) {
            self.updatedTransactionAction = updatedTransactionAction
            self.removedTransactionAction = removedTransactionAction
            self.restoreCompletedTransactionsFailedWithErrorAction = restoreCompletedTransactionsFailedWithErrorAction
            self.paymentQueueRestoreCompletedTransactionsFinishedAction = paymentQueueRestoreCompletedTransactionsFinishedAction
            self.updatedDownloadAction = updatedDownloadAction
            super.init()
            SKPaymentQueue.default().add(self)
        }
        
        
        deinit {
            SKPaymentQueue.default().remove(self)
        }
        
        public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
            updatedTransactionAction(transactions)
        }
        
        public func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
            removedTransactionAction(transactions)
        }
        
        public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
            restoreCompletedTransactionsFailedWithErrorAction(queue, error)
        }
        
        public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
            paymentQueueRestoreCompletedTransactionsFinishedAction(queue)
        }
        
        public func paymentQueue(_ queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload]) {
            updatedDownloadAction(downloads)
        }
    }
}


public extension SKPaymentQueue {
    var transactionObserver: SKPaymentTransactionObserverProxy {
        .shared
    }
}
