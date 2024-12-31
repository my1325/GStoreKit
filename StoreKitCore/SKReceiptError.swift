//
//  SKReceiptError.swift
//
//
//  Created by mayong on 2024/1/31.
//

import Foundation

public enum SKReceiptError: Error {
    case invalid(code: Int)
    case illegal
    case urlError(error: URLError)
    case underlying(error: Error)
    case nonHTTPResponse(response: URLResponse)
    case emptyTransaction
}

extension SKReceiptError: CustomStringConvertible {
    public var description: String {
        let message: String
        switch self {
        case .invalid(21000):
            message = "The App Store could not read the JSON object you provided."
        case .invalid(21002):
            message = "The data in the receipt-data property was malformed or missing."
        case .invalid(21003):
            message = "The receipt could not be authenticated."
        case .invalid(21004):
            message = "The shared secret you provided does not match the shared secret on file for your account."
        case .invalid(21005):
            message = "The receipt server is not currently available."
        case .invalid(21006):
            message = "This receipt is valid but the subscription has expired. When this status code is returned to your server, the receipt data is also decoded and returned as part of the response."
        case .invalid(21007):
            message = "This receipt is from the test environment, but it was sent to the production environment for verification. Send it to the test environment instead."
        case .invalid(21008):
            message = "This receipt is from the production environment, but it was sent to the test environment for verification. Send it to the production environment instead."
        case .emptyTransaction:
            message = "Empty transaction."
        case let .urlError(error):
            message = error.localizedDescription
        case let .underlying(error):
            message = error.localizedDescription
        case let .nonHTTPResponse(response):
            message = "Response is not NSHTTPURLResponse `\(response)`."
        default:
            message = "Unknown error occured."
        }
        return message
    }
}
