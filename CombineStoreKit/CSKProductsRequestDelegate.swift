//
//  CSKProductsRequestDelegate.swift
//  CombineStoreKit
//
//  Created by mayong on 2023/12/8.
//

import Foundation
import StoreKit
import Combine

public final class CSKProductsRequestDelegate: NSObject, SKProductsRequestDelegate {
    
    private static let requestDelegateKey = UnsafeRawPointer(bitPattern: 0x10086)!
    
    static func sharedWithParent(_ parent: SKProductsRequest) -> CSKProductsRequestDelegate {
        var delegate = objc_getAssociatedObject(parent, requestDelegateKey) as? CSKProductsRequestDelegate
        if delegate == nil {
            delegate = CSKProductsRequestDelegate()
            parent.delegate = delegate!
            objc_setAssociatedObject(parent, CSKProductsRequestDelegate.requestDelegateKey, delegate!, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return delegate!
    }
    
    let responseSubject: PassthroughSubject<SKProductsResponse, Error> = PassthroughSubject()
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        responseSubject.send(response)
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        responseSubject.send(completion: .failure(error))
    }
    
    deinit {
        responseSubject.send(completion: .finished)
    }
}

public extension SKProductsRequest {
    
    var productsRequestPublisher: AnyPublisher<SKProductsResponse, Error> {
        CSKProductsRequestDelegate.sharedWithParent(self)
            .responseSubject
            .eraseToAnyPublisher()
    }
}
