//
//  SKPaymentTransactionObserver.swift
//
//
//  Created by mayong on 2024/1/30.
//

import Foundation
import StoreKit

public enum VerifyMethod {
    case none
    case `default`
    case withPassword(password: String)
    
    public var isShouldVerify: Bool {
        switch self {
        case .none: return false
        default: return true
        }
    }
    
    public var password: String? {
        switch self {
        case .none, .default: return nil
        case let .withPassword(password): return password
        }
    }
}

open class SKObserverTransactionActionCancellable {
    typealias Observer = SKPaymentTransactionObserverProxy.Observer
    let updatedAction: Observer.PaymentTransactionAction
    let removedAction: Observer.PaymentTransactionAction
    let restoreFailedAction: Observer.PaymentQueueWithErrorAction
    let restoreCompletedAction: Observer.PaymentQueueAction
    let updatedDownloadAction: Observer.DownloadAction
    
    init(
        updatedAction: @escaping Observer.PaymentTransactionAction = { _ in },
        removedAction: @escaping Observer.PaymentTransactionAction = { _ in },
        restoreFailedAction: @escaping Observer.PaymentQueueWithErrorAction = { _, _ in },
        restoreCompletedAction: @escaping Observer.PaymentQueueAction = { _ in },
        updatedDownloadAction: @escaping Observer.DownloadAction = { _ in }
    ) {
        self.updatedAction = updatedAction
        self.removedAction = removedAction
        self.restoreFailedAction = restoreFailedAction
        self.restoreCompletedAction = restoreCompletedAction
        self.updatedDownloadAction = updatedDownloadAction
    }
    
    func scheduledUpdated(_ transactions: [SKPaymentTransaction]) {
        guard !isCancelled else { return }
        updatedAction(transactions)
    }
    
    func scheduledRemoved(_ transactions: [SKPaymentTransaction]) {
        guard !isCancelled else { return }
        removedAction(transactions)
    }
    
    func scheduledUpdatedDownload(_ downloads: [SKDownload]) {
        guard !isCancelled else { return }
        updatedDownloadAction(downloads)
    }
    
    func scheduledRestoreFailed(_ paymentQueue: SKPaymentQueue, _ error: Error) {
        guard !isCancelled else { return }
        restoreFailedAction(paymentQueue, error)
    }
    
    func scheduledRestoreCompleted(_ paymentQueue: SKPaymentQueue) {
        guard !isCancelled else { return }
        restoreCompletedAction(paymentQueue)
    }
    
    open var isCancelled: Bool = false
    
    open func cancel() {
        guard isCancelled else { return }
        isCancelled = true
    }
}

open class SKPaymentTransactionObserverProxy {
    private lazy var observer: Observer = .init(
        updatedAction: updated,
        removedAction: removed,
        restoreFailedAction: restoreCompletedFailed,
        restoreCompletedAction: restoreCompletedTransactions,
        updatedDownloadAction: updatedDownload
    )
    
    init() {
        _ = observer
    }
    
    private var updatedTransactionActions: [SKObserverTransactionActionCancellable] = []
    
    private var removedTransactionActions: [SKObserverTransactionActionCancellable] = []
    
    private var restoreCompletedTransactionsFailedWithErrorActions: [SKObserverTransactionActionCancellable] = []
    
    private var paymentQueueRestoreCompletedTransactionsFinishedActions: [SKObserverTransactionActionCancellable] = []
    
    private var updatedDownloadActions: [SKObserverTransactionActionCancellable] = []
    
    public static let shared = SKPaymentTransactionObserverProxy()
    
    func updated(_ transactions: [SKPaymentTransaction]) {
        prepareActions(&updatedTransactionActions) {
            $0.scheduledUpdated(transactions)
        }
    }
    
    func removed(_ transactions: [SKPaymentTransaction]) {
        prepareActions(&removedTransactionActions) {
            $0.scheduledRemoved(transactions)
        }
    }
    
    func restoreCompletedFailed(_ paymentQueue: SKPaymentQueue, _ error: Error) {
        prepareActions(&restoreCompletedTransactionsFailedWithErrorActions) {
            $0.scheduledRestoreFailed(paymentQueue, error)
        }
    }
    
    func restoreCompletedTransactions(_ paymentQueue: SKPaymentQueue) {
        prepareActions(&paymentQueueRestoreCompletedTransactionsFinishedActions) {
            $0.scheduledRestoreCompleted(paymentQueue)
        }
    }
    
    func updatedDownload(_ downloads: [SKDownload]) {
        prepareActions(&updatedDownloadActions) {
            $0.scheduledUpdatedDownload(downloads)
        }
    }
    
    func prepareActions(
        _ actions: inout [SKObserverTransactionActionCancellable],
        doAction: (SKObserverTransactionActionCancellable) -> Void
    ) {
        var needRemoveIndexSet: Set<Int> = []
        for index in 0 ..< actions.count {
            let action = actions[index]
            guard !action.isCancelled else {
                needRemoveIndexSet.insert(index)
                continue
            }
            doAction(action)
        }
        
        while let index = needRemoveIndexSet.popFirst() {
            actions.remove(at: index)
        }
    }
    
    @discardableResult
    open func onUpdated(_ transaction: @escaping Observer.PaymentTransactionAction) -> SKObserverTransactionActionCancellable {
        let cancellable = SKObserverTransactionActionCancellable(updatedAction: transaction)
        updatedTransactionActions.append(cancellable)
        return cancellable
    }
    
    @discardableResult
    open func onRemoved(_ transaction: @escaping Observer.PaymentTransactionAction) -> SKObserverTransactionActionCancellable {
        let cancellable = SKObserverTransactionActionCancellable(removedAction: transaction)
        removedTransactionActions.append(cancellable)
        return cancellable
    }
    
    @discardableResult
    open func onRestoreFailed(_ error: @escaping Observer.PaymentQueueWithErrorAction) -> SKObserverTransactionActionCancellable {
        let cancellable = SKObserverTransactionActionCancellable(restoreFailedAction: error)
        restoreCompletedTransactionsFailedWithErrorActions.append(cancellable)
        return cancellable
    }
    
    @discardableResult
    open func onRestoreCompleted(_ action: @escaping Observer.PaymentQueueAction) -> SKObserverTransactionActionCancellable {
        let cancellable = SKObserverTransactionActionCancellable(restoreCompletedAction: action)
        paymentQueueRestoreCompletedTransactionsFinishedActions.append(cancellable)
        return cancellable
    }
    

    @discardableResult
    open func onUpdatedDownload(_ action: @escaping Observer.DownloadAction) -> SKObserverTransactionActionCancellable {
        let cancellable = SKObserverTransactionActionCancellable(updatedDownloadAction: action)
        updatedDownloadActions.append(cancellable)
        return cancellable
    }
    
    public class Observer: NSObject, SKPaymentTransactionObserver {
        public typealias PaymentTransactionAction = ([SKPaymentTransaction]) -> Void
        public typealias PaymentQueueWithErrorAction = (SKPaymentQueue, Error) -> Void
        public typealias PaymentQueueAction = (SKPaymentQueue) -> Void
        public typealias DownloadAction = ([SKDownload]) -> Void
        
        let updatedAction: PaymentTransactionAction
        let removedAction: PaymentTransactionAction
        let restoreFailedAction: PaymentQueueWithErrorAction
        let restoreCompletedAction: PaymentQueueAction
        let updatedDownloadAction: DownloadAction
        
        init(
            updatedAction: @escaping PaymentTransactionAction,
            removedAction: @escaping PaymentTransactionAction,
            restoreFailedAction: @escaping PaymentQueueWithErrorAction,
            restoreCompletedAction: @escaping PaymentQueueAction,
            updatedDownloadAction: @escaping DownloadAction
        ) {
            self.updatedAction = updatedAction
            self.removedAction = removedAction
            self.restoreFailedAction = restoreFailedAction
            self.restoreCompletedAction = restoreCompletedAction
            self.updatedDownloadAction = updatedDownloadAction
            super.init()
            SKPaymentQueue.default().add(self)
        }
        
        deinit {
            SKPaymentQueue.default().remove(self)
        }
        
        public func paymentQueue(
            _ queue: SKPaymentQueue,
            updatedTransactions transactions: [SKPaymentTransaction]
        ) {
            updatedAction(transactions)
        }
        
        public func paymentQueue(
            _ queue: SKPaymentQueue,
            removedTransactions transactions: [SKPaymentTransaction]
        ) {
            removedAction(transactions)
        }
        
        public func paymentQueue(
            _ queue: SKPaymentQueue,
            restoreCompletedTransactionsFailedWithError error: Error
        ) {
            restoreFailedAction(queue, error)
        }
        
        public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
            restoreCompletedAction(queue)
        }
        
        public func paymentQueue(
            _ queue: SKPaymentQueue,
            updatedDownloads downloads: [SKDownload]
        ) {
            updatedDownloadAction(downloads)
        }
    }
}

public extension SKPaymentQueue {
    var transactionObserver: SKPaymentTransactionObserverProxy {
        .shared
    }
}
