//
//  SKProductDelegateProxy.swift
//  
//
//  Created by mayong on 2024/1/30.
//

import Foundation
import StoreKit

public class SKProductDelegateProxy: NSObject, SKProductsRequestDelegate {
    public typealias SKProductDelegateResponseAction = (SKProductsResponse) -> Void
    public typealias SKProductDelegateErrorAction = (Error) -> Void
    
    fileprivate static let requestDelegateKey = UnsafeRawPointer(bitPattern: 0x10086)!
    
    let responseAction: SKProductDelegateResponseAction
    let errorAction: SKProductDelegateErrorAction
    
    init(
        responseAction: @escaping SKProductDelegateResponseAction,
         errorAction: @escaping SKProductDelegateErrorAction
    ) {
        self.responseAction = responseAction
        self.errorAction = errorAction
    }
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        responseAction(response)
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        errorAction(error)
    }
}

public extension SKProductsRequest {
    func start(
        _ responseAction: @escaping SKProductDelegateProxy.SKProductDelegateResponseAction,
        errorAction: @escaping SKProductDelegateProxy.SKProductDelegateErrorAction
    ) {
        let skDelegate = SKProductDelegateProxy(responseAction: responseAction, errorAction: errorAction)
        delegate = skDelegate
        objc_setAssociatedObject(self, SKProductDelegateProxy.requestDelegateKey, skDelegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        start()
    }
}

//
//    static func products(_ productIds: Set<String>) async throws -> [SKProduct] {
//        try await withCheckedThrowingContinuation { continuation in
//            let productsRequest = SKProductsRequest(productIdentifiers: productIds)
//            productsRequest.start {
//                continuation.resume(returning: $0.products)
//            } errorAction: {
//                continuation.resume(throwing: $0)
//            }
//        }
//    }
//}
