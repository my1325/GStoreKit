//
//  CSKPaymentQueue+Combine.swift
//  CombineStoreKit
//
//  Created by mayong on 2023/12/8.
//

import Foundation
import StoreKit
import Combine
import CombineExt

public enum CSKReceiptError: Error {
    case invalid(code: Int)
    case illegal
    case urlError(error: URLError)
    case nonHTTPResponse(response: URLResponse)
}

extension CSKReceiptError: CustomStringConvertible {
    public var description: String {
        let message: String
        switch self {
        case .invalid(21000):
            message = "The App Store could not read the JSON object you provided."
        case .invalid(21002):
            message = "The data in the receipt-data property was malformed or missing."
        case .invalid(21003):
            message = "The receipt could not be authenticated."
        case .invalid(21004):
            message = "The shared secret you provided does not match the shared secret on file for your account."
        case .invalid(21005):
            message = "The receipt server is not currently available."
        case .invalid(21006):
            message = "This receipt is valid but the subscription has expired. When this status code is returned to your server, the receipt data is also decoded and returned as part of the response."
        case .invalid(21007):
            message = "This receipt is from the test environment, but it was sent to the production environment for verification. Send it to the test environment instead."
        case .invalid(21008):
            message = "This receipt is from the production environment, but it was sent to the test environment for verification. Send it to the production environment instead."
        case let .urlError(error):
            message = error.localizedDescription
        case let .nonHTTPResponse(response):
            message = "Response is not NSHTTPURLResponse `\(response)`."
        default:
            message = "Unknown error occured."
        }
        return message
    }
}

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
                .mapError({ CSKReceiptError.urlError(error: $0) })
                .map({ ($0.response as! HTTPURLResponse, $0.data) })
                .tryMap({ pair -> Any in
                    if 200 ..< 300 ~= pair.0.statusCode {
                        return try JSONSerialization.jsonObject(with: pair.1, options: [.fragmentsAllowed])
                    }
                    throw CSKReceiptError.nonHTTPResponse(response: pair.0)
                })
                .flatMap({ [unowned self] json -> AnyPublisher<SKPaymentTransaction, Error> in
                    self.verificationResultPublisher(for: transaction, response: json)
                })
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
                return Fail(outputType: SKPaymentTransaction.self, failure: CSKReceiptError.illegal)
                    .eraseToAnyPublisher()
            }
        } else {
            let error = CSKReceiptError.invalid(code: state)
            return Fail(outputType: SKPaymentTransaction.self, failure: error)
                .eraseToAnyPublisher()
        }
    }
}

public extension SKPaymentQueue {
    var transactionObserver: CSKPaymentTransactionObserver {
        return CSKPaymentTransactionObserver.shared
    }

    func restoreCompletedTransactionsPublisher() -> AnyPublisher<SKPaymentQueue, Error> {
        let success = transactionObserver.csk_paymentQueueRestoreCompletedTransactionsFinished
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        let error = transactionObserver.csk_restoreCompletedTransactionsFailedWithError
            .tryMap { _, error -> SKPaymentQueue in
                throw SKError(_nsError: error as NSError)
            }
            .eraseToAnyPublisher()
        
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
                let cancelable = self.transactionObserver.csk_updatedTransaction
                    .setFailureType(to: Error.self)
                    .flatMap({ transaction -> AnyPublisher<SKPaymentTransaction, Error> in
                        switch transaction.transactionState {
                        case .purchased:
                            return self.verifyReceiptPublisher(transaction: transaction)
                        default: print("transaction state = \(transaction.transactionState)")
                        }
                        return Just(transaction).setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    })
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
            let cancelable = self.transactionObserver.csk_updatedTransaction
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
            let cancelable = self.transactionObserver.csk_updatedDownload
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
