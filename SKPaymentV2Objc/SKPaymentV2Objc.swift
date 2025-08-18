//
//  SKPaymentV2Objc.swift
//  GStoreKit
//
//  Created by mayong on 2025/8/14.
//

import Foundation
import StoreKit

@available(iOS 15.0, *)
public typealias SKPaymentV2Result = (SKPaymentV2ObjcTransaction?, Error?)

@available(iOS 15.0, *)
public enum SKPaymentV2Error: Error {
    case unverifiedTransaction(Transaction, Error)
    case paymentCancelled
    case unknownError(String)
    
    var localizedDescription: String {
        switch self {
        case .unverifiedTransaction(_, let error):
            return "Transaction verification failed: \(error.localizedDescription)"
        case .paymentCancelled:
            return "Payment was cancelled by the user."
        case .unknownError(let message):
            return "Unknown error occurred: \(message)"
        }
    }
}

@available(iOS 15.0, *)
public extension Product.PurchaseResult {
    var transaction: Transaction {
        get throws {
            switch self {
            case let .success(.verified(transaction)):
                return transaction
            case let .success(.unverified(transaction, error)):
                throw SKPaymentV2Error.unverifiedTransaction(transaction, error)
            case .userCancelled:
                throw SKPaymentV2Error.paymentCancelled
            case .pending:
                throw SKPaymentV2Error.unknownError("Purchase is pending.")
            @unknown default:
                throw SKPaymentV2Error.unknownError("Unknown purchase result.")
            }
        }
    }
}

@available(iOS 15.0, *)
open class SKPaymentV2Objc: NSObject {
    @objc public static let shared = SKPaymentV2Objc()
    
    private let updatedObserver = SKPaymentV2ObjcObserver()
    private let currentEntitlementsObserver = SKPaymentV2ObjcObserver()
    private let taskManager = SKPaymentTaskManager()
    
    // Task 管理
    private var observerTasks: [Task<Void, Never>] = []
    
    override private init() {
        super.init()
        startObservingTransactions()
    }
    
    deinit {
        cancelAllTasks()
    }
    
    @objc public func purchase(
        product: SKPaymentV2ObjcProduct,
        completion: @escaping @Sendable (SKPaymentV2ObjcTransaction?, Error?) -> Void
    ) {
        Task {
            await taskManager.executeOnceTask(
                priority: .userInitiated,
                operation: {
                    try await product.product.purchase()
                        .transaction
                },
                completion: { result in
                    switch result {
                    case .success(let transaction):
                        completion(SKPaymentV2ObjcTransaction(transaction: transaction), nil)
                    case .failure(let error):
                        completion(nil, error)
                    }
                }
            )
        }
    }
    
    @objc public func fetchProducts(
        for identifiers: [String],
        completion: @escaping @Sendable ([SKPaymentV2ObjcProduct]?, Error?) -> Void
    ) {
        let taskId = "fetchProducts-\(identifiers.joined(separator: ","))"
        
        Task {
            await taskManager.executeTask(
                id: taskId,
                priority: .userInitiated,
                operation: {
                    try await Product.products(for: identifiers)
                },
                completion: { result in
                    switch result {
                    case .success(let products):
                        completion(products.map(SKPaymentV2ObjcProduct.init), nil)
                    case .failure(let error):
                        completion(nil, error)
                    }
                }
            )
        }
    }
    
    /// Observe transaction updates.
    @objc public func observeUpdatedTransactions(
        _ action: @escaping @Sendable (SKPaymentV2ObjcTransaction?, Error?) -> Void
    ) {
        Task { [weak self] in
            await self?.updatedObserver.observeUpdatedTransactions(action)
        }
    }
    
    /// Observe current entitlements for restore functionality.
    @objc public func observeCurrentEntitlements(
        _ action: @escaping @Sendable (SKPaymentV2ObjcTransaction?, Error?) -> Void
    ) {
        Task { [weak self] in
            await self?.currentEntitlementsObserver.observeUpdatedTransactions(action)
        }
    }
    
    // MARK: - Task Management
    
    /// 取消所有正在进行的任务
    @objc public func cancelAllTasks() {
        observerTasks.forEach { $0.cancel() }
        observerTasks.removeAll()
        
        Task {
            await taskManager.cancelAllTasks()
        }
    }
    
    /// 重新开始观察事务（用于恢复场景）
    @objc public func restartObserving() {
        cancelAllTasks()
        startObservingTransactions()
    }
    
    /// 获取当前活跃任务数量
    @objc public func getActiveTaskCount(completion: @escaping @Sendable (Int) -> Void) {
        Task {
            let count = await taskManager.activeTaskCount
            await MainActor.run {
                completion(count)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func startObservingTransactions() {
        let updatesTask = Task { [weak self] in
            guard let self = self else { return }
            for await update in Transaction.updates {
                guard !Task.isCancelled else { break }
                await self.handleTransactionUpdate(update, observer: self.updatedObserver)
            }
        }
        
        let entitlementsTask = Task { [weak self] in
            guard let self = self else { return }
            for await update in Transaction.currentEntitlements {
                guard !Task.isCancelled else { break }
                await self.handleTransactionUpdate(update, observer: self.currentEntitlementsObserver)
            }
        }
        
        observerTasks.append(contentsOf: [updatesTask, entitlementsTask])
    }
    
    private func handleTransactionUpdate(
        _ update: VerificationResult<Transaction>,
        observer: SKPaymentV2ObjcObserver
    ) async {
        let result: SKPaymentV2Result
        
        switch update {
        case .verified(let transaction):
            result = (SKPaymentV2ObjcTransaction(transaction: transaction), nil)
        case .unverified(let transaction, let error):
            result = (SKPaymentV2ObjcTransaction(transaction: transaction), error)
        }
        
        await observer.scheduleTransactionUpdateObserver(result: result)
    }
}
