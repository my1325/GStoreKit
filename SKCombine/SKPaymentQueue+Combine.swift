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
#if canImport(SKCore)
    import SKCore
#endif

public extension SKPaymentQueue {
    func verifyReceiptPublisher(transaction: SKPaymentTransaction, excludeOldTransaction: Bool = false) -> AnyPublisher<SKPaymentTransaction, Error> {
        #if DEBUG
            let verifyReceiptURLString = "https://sandbox.itunes.apple.com/verifyReceipt"
        #else
            let verifyReceiptURLString = "https://buy.itunes.apple.com/verifyReceipt"
        #endif
        let url = URL(string: verifyReceiptURLString)!
        do {
            let receiptURL = Bundle.main.appStoreReceiptURL
            let data = try Data(contentsOf: receiptURL!, options: [])
            let base64 = data.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            let json = try JSONSerialization.data(withJSONObject:
                [
                    "receipt-data": base64,
                    "exclude-old-transactions": excludeOldTransaction
                ], options: [])

            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = json

            return URLSession.shared.dataTaskPublisher(for: request)
                .timeout(30, scheduler: DispatchQueue.global(qos: .background))
                .mapError { SKReceiptError.urlError(error: $0) }
                .map { ($0.response as! HTTPURLResponse, $0.data) }
                .tryMap { pair -> Any in
                    if 200 ..< 300 ~= pair.0.statusCode {
                        return try JSONSerialization.jsonObject(with: pair.1, options: [.fragmentsAllowed])
                    }
                    throw SKReceiptError.nonHTTPResponse(response: pair.0)
                }
                .flatMap { [unowned self] json -> AnyPublisher<SKPaymentTransaction, Error> in
                    self.verificationResultPublisher(for: transaction, response: json)
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(outputType: SKPaymentTransaction.self, failure: error)
                .eraseToAnyPublisher()
        }
    }

    func verificationResultPublisher(for transaction: SKPaymentTransaction, response: Any) -> AnyPublisher<SKPaymentTransaction, Error> {
        let json = response as! [String: AnyObject]
        let state = json["status"] as! Int
        if state == 0 {
            print(json)
            let receipt = json["receipt"]!
            let inApp = receipt["in_app"] as! [[String: Any]]
            let contains = inApp.contains { element -> Bool in
                let productId = element["product_id"] as! String
                return productId == transaction.payment.productIdentifier
            }
            if contains {
                return Just(transaction).setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            } else {
                return Fail(outputType: SKPaymentTransaction.self, failure: SKReceiptError.illegal)
                    .eraseToAnyPublisher()
            }
        } else {
            let error = SKReceiptError.invalid(code: state)
            return Fail(outputType: SKPaymentTransaction.self, failure: error)
                .eraseToAnyPublisher()
        }
    }
}

public extension SKPaymentTransactionObserverProxy {
    var paymentQueueRestoreCompletedTransactionsFinishedPublisher: AnyPublisher<SKPaymentQueue, Error> {
        AnyPublisher.create { subscriber in
            var skTarget: NSObject? = NSObject()
            SKPaymentTransactionObserverProxy.shared.add(skTarget!, paymentQueueRestoreCompletedTransactionsFinishedAction: { skQueue in
                subscriber.send(skQueue)
            })
            return AnyCancellable {
                skTarget = nil
            }
        }
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
    }

    var restoreCompletedTransactionsFailedWithErrorPublisher: AnyPublisher<SKPaymentQueue, Error> {
        AnyPublisher.create ({ subscriber in
            var skTarget: NSObject? = NSObject()
            SKPaymentTransactionObserverProxy.shared.add(skTarget!, restoreCompletedTransactionsFailedWithErrorAction: { skQueue, error in
                subscriber.send((skQueue, error))
            })
            return AnyCancellable {
                skTarget = nil
            }
        })
        .setFailureType(to: Error.self)
        .tryMap { _, error -> SKPaymentQueue in
            throw SKError(_nsError: error as NSError)
        }
        .eraseToAnyPublisher()
    }
    
    var updatedTransactionPublisher: AnyPublisher<SKPaymentTransaction, Never> {
        AnyPublisher.create({ subscriber in
            var skTarget: NSObject? = NSObject()
            SKPaymentTransactionObserverProxy.shared.add(skTarget!, updatedTransactionAction: {
                $0.forEach {
                    subscriber.send($0)
                }
            })
            return AnyCancellable {
                skTarget = nil
            }
        })
    }
    
    var updatedDownloadPublisher: AnyPublisher<SKDownload, Never> {
        AnyPublisher.create({ subscriber in
            var skTarget: NSObject? = NSObject()
            SKPaymentTransactionObserverProxy.shared.add(skTarget!, updatedDownloadAction: {
                $0.forEach({ subscriber.send($0) })
            })
            return AnyCancellable {
                skTarget = nil
            }
        })
    }
}

public extension SKPaymentQueue {

    func restoreCompletedTransactionsPublisher() -> AnyPublisher<SKPaymentQueue, Error> {
        let success = transactionObserver.paymentQueueRestoreCompletedTransactionsFinishedPublisher
        let error = transactionObserver.restoreCompletedTransactionsFailedWithErrorPublisher

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

    func addPublisher(product: SKProduct, shouldVerify: Bool) -> AnyPublisher<SKPaymentTransaction, Error> {
        let payment = SKPayment(product: product)

        if shouldVerify {
            return AnyPublisher.create { subscriber in
                let cancelable = self.transactionObserver.updatedTransactionPublisher
                    .setFailureType(to: Error.self)
                    .flatMap { transaction -> AnyPublisher<SKPaymentTransaction, Error> in
                        switch transaction.transactionState {
                        case .purchased:
                            return self.verifyReceiptPublisher(transaction: transaction)
                        default: print("transaction state = \(transaction.transactionState)")
                        }
                        return Just(transaction).setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                    .sink(receiveCompletion: {
                        subscriber.send(completion: $0)
                    }, receiveValue: {
                        subscriber.send($0)
                    })
                return AnyCancellable {
                    cancelable.cancel()
                }
            }
        }

        return AnyPublisher.create { subscriber in
            let cancelable = self.transactionObserver.updatedTransactionPublisher
                .setFailureType(to: Error.self)
                .sink(receiveCompletion: {
                    subscriber.send(completion: $0)
                }, receiveValue: { transaction in
                    switch transaction.transactionState {
                    case .purchased:
                        SKPaymentQueue.default().finishTransaction(transaction)
                        subscriber.send(transaction)
                        subscriber.send(completion: .finished)

                    case .failed:
                        SKPaymentQueue.default().finishTransaction(transaction)
                        if let err = transaction.error {
                            subscriber.send(completion: .failure(err))
                        } else {
                            subscriber.send(transaction)
                            subscriber.send(completion: .finished)
                        }

                    case .restored:
                        SKPaymentQueue.default().finishTransaction(transaction)
                        subscriber.send(transaction)

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

    @available(iOS 12.0, *)
    func startPublisher(downloads: [SKDownload]) -> AnyPublisher<SKDownload, Error> {
        AnyPublisher.create { subscriber in
            let cancelable = self.transactionObserver.updatedDownloadPublisher
                .setFailureType(to: Error.self)
                .sink(receiveCompletion: {
                    subscriber.send(completion: $0)
                }, receiveValue: { download in
                    switch download.state {
                    case .waiting:
                        print("waiting")
                    case .active:
                        print("active")
                    case .finished:
                        subscriber.send(download)
                    case .failed:
                        if let downloadError = download.error {
                            subscriber.send(completion: .failure(downloadError))
                        }
                    case .cancelled:
                        subscriber.send(completion: .finished)
                    case .paused:
                        print("paused")
                    }
                })
            self.start(downloads)
            return AnyCancellable {
                cancelable.cancel()
            }
        }
    }
}
