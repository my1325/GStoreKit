//
//  CSKReceiptRefreshRequestDelegate.swift
//  CombineStoreKit
//
//  Created by mayong on 2023/12/8.
//

import Foundation
import StoreKit
import Combine
import CombineExt

public class SKReceiptRefreshRequestDelegate: NSObject, SKRequestDelegate {

    private static let delegateKey = UnsafeRawPointer(bitPattern: 0x10086)!
    
    static func sharedWithParent(_ parent: SKReceiptRefreshRequest) -> SKReceiptRefreshRequestDelegate {
        var delegate = objc_getAssociatedObject(parent, delegateKey) as? SKReceiptRefreshRequestDelegate
        if delegate == nil {
            delegate = SKReceiptRefreshRequestDelegate()
            objc_setAssociatedObject(parent, delegateKey, delegate!, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        return delegate!
    }
    
    let responseSubject = PassthroughSubject<SKProductsResponse, Error>()
    
    public func requestDidFinish(_ request: SKRequest) {
        responseSubject.send(completion: .finished)
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        responseSubject.send(completion: .failure(error))
    }

    deinit {
        responseSubject.send(completion: .finished)
    }
}

extension SKReceiptRefreshRequest {
    public var requestPublisher: AnyPublisher<Void, Never> {
        SKReceiptRefreshRequestDelegate.sharedWithParent(self)
            .responseSubject
            .map({ _ in })
            .ignoreFailure()
            .eraseToAnyPublisher()
    }
}
