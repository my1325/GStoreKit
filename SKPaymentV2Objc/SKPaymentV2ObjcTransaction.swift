//
//  File.swift
//  GStoreKit
//
//  Created by mayong on 2025/8/14.
//

import Foundation
import StoreKit

@available(iOS 15.0, *)
public final class SKPaymentV2ObjcTransaction: NSObject {
    let transaction: Transaction
    init(transaction: Transaction) {
        self.transaction = transaction
        super.init()
    }
    
    /// The JSON representation of the transaction.
    @objc public func jsonData() -> Data {
        transaction.jsonRepresentation
    }
    
    @objc public func id() -> String {
        String(transaction.id)
    }
    
    /// The ID of the original transaction for `productID` or`subscriptionGroupID` if this is a
    /// subscription.
    @objc public func originalId() -> String {
        String(transaction.originalID)
    }
    
    /// Uniquely identifies a subscription purchase.
    /// - Note: Only for subscriptions.
    @objc public func webOrderLineItemId() -> String? {
        transaction.webOrderLineItemID
    }
    
    /// Identifies the product the transaction is for.
    @objc public func productId() -> String {
        transaction.productID
    }
    
    /// Identifies the subscription group the transaction is for.
    /// - Note: Only for subscriptions.
    @objc public func subscriptionGroupID() -> String? {
        transaction.subscriptionGroupID
    }
    
    /// Identifies the application the transaction is for.
    @objc public func appBundleId() -> String {
        transaction.appBundleID
    }
    
    /// The date this transaction occurred on.
    @objc public func purchaseDate() -> Date {
        return transaction.purchaseDate
    }
    
    /// The date the original transaction for `productID` or`subscriptionGroupID` occurred on.
    @objc public func originalPurchaseDate() -> Date {
        transaction.originalPurchaseDate
    }
    
    /// The date the users access to `productID` expires
    /// - Note: Only for subscriptions.
    @objc public func expirationDate() -> Date? {
        transaction.expirationDate
    }
    
    /// Quantity of `productID` purchased in the transaction.
    /// - Note: Always 1 for non-consumables and auto-renewable suscriptions.
    @objc public func purchasedQuantity() -> Int {
        transaction.purchasedQuantity
    }
    
    /// If this transaction was upgraded to a subscription with a higher level of service.
    /// - Important: If this property is `true`, look for a new transaction for a subscription with a
    ///              higher level of service.
    /// - Note: Only for subscriptions.
    @objc public func isUpgraded() -> Bool {
        transaction.isUpgraded
    }
    
    /// The date the transaction was revoked, or `nil` if it was not revoked.
    @objc public func revocationDate() -> Date? {
        transaction.revocationDate
    }
    
    /// The type of `productID`.
    @objc public func productType() -> String {
        transaction.productType.rawValue
    }
    
    /// If an app account token was added as a purchase option when purchasing, this property will
    /// be the token provided. If no token was provided, this will be `nil`.
    @objc public func appAccountToken() -> UUID? {
        return transaction.appAccountToken
    }
    
//    /// A SHA-384 hash of `AppStore.deviceVerificationID` appended after
//    /// `deviceVerificationNonce` (both lowercased UUID strings).
//    public let deviceVerification: Data
    @objc public func deviceVerification() -> Data {
        transaction.deviceVerification
    }

//
//    /// The nonce used when computing `deviceVerification`.
//    /// - SeeAlso: `AppStore.deviceVerificationID`
//    public let deviceVerificationNonce: UUID
    @objc public func deviceVerificationNonce() -> UUID {
        transaction.deviceVerificationNonce
    }

//
//    /// Whether the user purchased this transaction, or has access to it via family sharing.
//    public let ownershipType: Transaction.OwnershipType
    @objc public func ownershipType() -> String {
        transaction.ownershipType.rawValue
    }

//
//    /// The date this transaction was generated and signed.
//    public let signedDate: Date
    @objc public func signedDate() -> Date {
        transaction.signedDate
    }
    
    @objc public func finish(_ completion: @escaping @Sendable () -> Void) {
        Task {
            await transaction.finish()
            await MainActor.run {
                completion()
            }
        }
    }
}
