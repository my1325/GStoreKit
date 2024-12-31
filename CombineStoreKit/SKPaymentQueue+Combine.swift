//
//  CSKPaymentQueue+Combine.swift
//  CombineStoreKit
//
//  Created by mayong on 2023/12/8.
//

import Combine
import CombineExt
import Foundation
import StoreKit
#if canImport(StoreKitCore)
    import StoreKitCore
#endif


public extension SKPaymentTransactionObserverProxy {
    var restoreCompletedPublisher: AnyPublisher<SKPaymentQueue, Error> {
        AnyPublisher.create { subscriber in
            let cancellable = SKPaymentTransactionObserverProxy.shared
                .onRestoreCompleted { skQueue in
                    subscriber.send(skQueue)
                }
            return AnyCancellable(cancellable.cancel)
        }
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }

    var restorFailedPublisher: AnyPublisher<SKPaymentQueue, Error> {
        AnyPublisher.create { subscriber in
            let cancellable = SKPaymentTransactionObserverProxy.shared
                .onRestoreFailed  { skQueue, error in
                subscriber.send((skQueue, error))
            }
            return AnyCancellable(cancellable.cancel)
        }
        .setFailureType(to: Error.self)
        .tryMap { _, error -> SKPaymentQueue in
            throw SKError(_nsError: error as NSError)
        }
        .eraseToAnyPublisher()
    }

    var updatedPublisher: AnyPublisher<SKPaymentTransaction, Never> {
        AnyPublisher.create { subscriber in
            let cancellable = SKPaymentTransactionObserverProxy.shared
                .onUpdated { transactions in
                    transactions.forEach { subscriber.send($0) }
                }
            return AnyCancellable(cancellable.cancel)
        }
    }

    var updatedDownloadPublisher: AnyPublisher<SKDownload, Never> {
        AnyPublisher.create { subscriber in
            let cancellable = SKPaymentTransactionObserverProxy.shared
                .onUpdatedDownload {
                $0.forEach { subscriber.send($0) }
            }
            return AnyCancellable(cancellable.cancel)
        }
    }
}

public extension SKPaymentQueue {
    func restoreCompletedPublisher() -> AnyPublisher<SKPaymentQueue, Error> {
        let success = transactionObserver.restoreCompletedPublisher
        let error = transactionObserver.restorFailedPublisher

        return AnyPublisher<SKPaymentQueue, Error>.create { subscriber in
            let cancelable = success.amb(error)
                .sink(receiveCompletion: {
                    subscriber.send(completion: $0)
                }, receiveValue: {
                    subscriber.send($0)
                })

            self.restoreCompletedTransactions()

            return AnyCancellable {
                cancelable.cancel()
            }
        }
    }
    
    func addPublisher(_ productId: String) -> AnyPublisher<SKPaymentTransaction, Error> {
        let payment = SKMutablePayment()
        payment.productIdentifier = productId
        return publisher(for: payment)
    }

    func addPublisher(product: SKProduct) -> AnyPublisher<SKPaymentTransaction, Error> {
        publisher(for: SKPayment(product: product))
    }
    
    private func publisher(for payment: SKPayment) -> AnyPublisher<SKPaymentTransaction, Error> {
        AnyPublisher.create { subscriber in
            let cancelable = self.transactionObserver.updatedPublisher
                .setFailureType(to: Error.self)
                .sink(receiveCompletion: {
                    subscriber.send(completion: $0)
                }, receiveValue: { transaction in
                    switch transaction.transactionState {
                    case .purchased, .restored:
                        subscriber.send(transaction)
                        subscriber.send(completion: .finished)
                    case .failed:
                        subscriber.send(completion: .failure(transaction.error ?? SKReceiptError.illegal))
                    default:
                        subscriber.send(transaction)
                    }
                })
            self.add(payment)
            return AnyCancellable {
                cancelable.cancel()
            }
        }
    }
}
