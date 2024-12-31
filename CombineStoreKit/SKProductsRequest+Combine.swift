//
//  CSKProductsRequestDelegate.swift
//  CombineStoreKit
//
//  Created by mayong on 2023/12/8.
//

import Foundation
import StoreKit
import Combine
import CombineExt
#if canImport(StoreKitCore)
import StoreKitCore
#endif

public extension SKProductsRequest {
    
    var productsRequestPublisher: AnyPublisher<SKProductsResponse, Error> {
        AnyPublisher.create({ [weak self] subscriber in
            self?.start({
                subscriber.send($0)
            }, errorAction: {
                subscriber.send(completion: .failure($0))
            })
            return AnyCancellable {
                self?.cancel()
            }
        })
    }
}
