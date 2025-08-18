//
//  SKPaymentV2ObjcProduct.swift
//  GStoreKit
//
//  Created by mayong on 2025/8/14.
//

import Foundation
import StoreKit

@available(iOS 15.0, *)
public final class SKPaymentV2ObjcProduct: NSObject {
    let product: Product
    
    init(product: Product) {
        self.product = product
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// The raw JSON representation of the product.
    @objc public func jsonData() -> Data {
        product.jsonRepresentation
    }

    /// The unique product identifier.
    @objc public var id: String {
        product.id
    }

    /// The type of the product.
    @objc public var type: String {
        product.type.rawValue
    }

    /// A localized display name of the product.
    @objc public var displayName: String {
        product.displayName
    }

    /// A localized description of the product.
    @objc public var productDescription: String {
        product.description
    }

    /// The price of the product in local currency.
    @objc public var price: Decimal {
        product.price
    }

    /// A localized string representation of price.
    @objc public var displayPrice: String {
        product.displayPrice
    }

    /// Whether the product is available for family sharing.
    @objc public var isFamilyShareable: Bool {
        product.isFamilyShareable
    }
}

