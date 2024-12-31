//
//  SKProductDelegateProxy.swift
//  
//
//  Created by mayong on 2024/1/30.
//

import Foundation
import StoreKit
#if canImport(StoreKitCore)
import StoreKitCore
#endif

public extension SKProductsRequest {
    
    static func products(_ productIds: Set<String>) async throws -> [SKProduct] {
        try await withCheckedThrowingContinuation { continuation in
            let productsRequest = SKProductsRequest(productIdentifiers: productIds)
            productsRequest.start {
                continuation.resume(returning: $0.products)
            } errorAction: {
                continuation.resume(throwing: $0)
            }
        }
    }
    
    static func product(_ productId: String) async throws -> SKProduct? {
        try await products([productId]).first
    }
}
