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
#if canImport(SKCore)
import SKCore
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
