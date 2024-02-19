//
//  SKProductDelegateProxy.swift
//  
//
//  Created by mayong on 2024/1/30.
//

import Foundation
import StoreKit
#if canImport(SKCore)
import SKCore
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
}
