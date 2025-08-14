//
//  File.swift
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
    
//    /// The raw JSON representation of the product.
//    public var jsonRepresentation: Data { get }
    @objc public func jsonData() -> Data {
        product.jsonRepresentation
    }

    /// The unique product identifier.
//    public let id: String
    @objc public func id() -> String {
        product.id
    }

    /// The type of the product.
//    public let type: Product.ProductType
    @objc public func type() -> String {
        product.type.rawValue
    }

    /// A localized display name of the product.
//    public let displayName: String
    @objc public func displayName() -> String {
        product.displayName
    }

    /// A localized description of the product.
//    public let description: String
//    @objc public func description() -> String {
//        product.description
//    }

    /// The price of the product in local currency.
//    public let price: Decimal
    @objc public func price() -> Decimal {
        product.price
    }

    /// A localized string representation of `price`.
//    public let displayPrice: String
    @objc public func displayPrice() -> String {
        product.displayPrice
    }

    /// Whether the product is available for family sharing.
//    public let isFamilyShareable: Bool
    @objc public func isFamilyShareable() -> Bool {
        product.isFamilyShareable
    }
}

