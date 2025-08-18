//
//  SKPaymentV2ObjcTransaction.swift
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
    
    // MARK: - Basic Properties
    
    /// The JSON representation of the transaction.
    @objc public var jsonData: Data {
        transaction.jsonRepresentation
    }
    
    /// The unique transaction identifier.
    @objc public var id: String {
        String(transaction.id)
    }
    
    /// The ID of the original transaction for productID or subscriptionGroupID if this is a subscription.
    @objc public var originalId: String {
        String(transaction.originalID)
    }
    
    /// Identifies the product the transaction is for.
    @objc public var productId: String {
        transaction.productID
    }
    
    /// Identifies the application the transaction is for.
    @objc public var appBundleId: String {
        transaction.appBundleID
    }
    
    // MARK: - Date Properties
    
    /// The date this transaction occurred on.
    @objc public var purchaseDate: Date {
        transaction.purchaseDate
    }
    
    /// The date the original transaction for productID or subscriptionGroupID occurred on.
    @objc public var originalPurchaseDate: Date {
        transaction.originalPurchaseDate
    }
    
    /// The date this transaction was generated and signed.
    @objc public var signedDate: Date {
        transaction.signedDate
    }
    
    // MARK: - Optional Properties
    
    /// Uniquely identifies a subscription purchase. Only for subscriptions.
    @objc public var webOrderLineItemId: String? {
        transaction.webOrderLineItemID
    }
    
    /// Identifies the subscription group the transaction is for. Only for subscriptions.
    @objc public var subscriptionGroupID: String? {
        transaction.subscriptionGroupID
    }
    
    /// The date the users access to productID expires. Only for subscriptions.
    @objc public var expirationDate: Date? {
        transaction.expirationDate
    }
    
    /// The date the transaction was revoked, or nil if it was not revoked.
    @objc public var revocationDate: Date? {
        transaction.revocationDate
    }
    
    /// If an app account token was added as a purchase option when purchasing, this property will be the token provided.
    @objc public var appAccountToken: UUID? {
        transaction.appAccountToken
    }
    
    // MARK: - Numeric Properties
    
    /// Quantity of productID purchased in the transaction. Always 1 for non-consumables and auto-renewable subscriptions.
    @objc public var purchasedQuantity: Int {
        transaction.purchasedQuantity
    }
    
    // MARK: - Boolean Properties
    
    /// If this transaction was upgraded to a subscription with a higher level of service. Only for subscriptions.
    @objc public var isUpgraded: Bool {
        transaction.isUpgraded
    }
    
    // MARK: - String Enum Properties
    
    /// The type of productID.
    @objc public var productType: String {
        transaction.productType.rawValue
    }
    
    /// Whether the user purchased this transaction, or has access to it via family sharing.
    @objc public var ownershipType: String {
        transaction.ownershipType.rawValue
    }
    
    // MARK: - Data Properties
    
    /// A SHA-384 hash of AppStore.deviceVerificationID appended after deviceVerificationNonce.
    @objc public var deviceVerification: Data {
        transaction.deviceVerification
    }
    
    /// The nonce used when computing deviceVerification.
    @objc public var deviceVerificationNonce: UUID {
        transaction.deviceVerificationNonce
    }
    
    // MARK: - Methods
    
    /// Finishes the transaction.
    @objc public func finish(_ completion: @escaping @Sendable () -> Void) {
        Task {
            await transaction.finish()
            await MainActor.run {
                completion()
            }
        }
    }
}
