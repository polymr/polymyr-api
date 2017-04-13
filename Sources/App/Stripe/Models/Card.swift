//
//  Card.swift
//  Stripe
//
//  Created by Hakon Hanesand on 12/2/16.
//
//

import Node

public enum Verification: String, NodeConvertible {
    
    case pass
    case fail
    case unavailable
    case unchecked
}

public enum Brand: String, NodeConvertible {
    
    case visa = "Visa"
    case americanExpress = "American Express"
    case masterCard = "MasterCard"
    case discover = "Discover"
    case jcb = "JCB"
    case dinerClub = "Diners Club"
    case unknwon = "Unknown"
}

public enum Funding: String, NodeConvertible {
    
    case credit
    case debit
    case prepaid
    case unknown
}

public enum TokenizationMethod: String, NodeConvertible {
    
    case applePay = "apple_pay"
    case androidPay = "android_pay"
}

public final class Card: NodeConvertible {
    
    static let type = "card"

    public let id: String
    public let address_city: String?
    public let address_county: String?
    public let address_line1: String?
    public let address_line2: String?
    public let address_line1_check: Verification?
    public let address_state: String?
    public let address_zip: String?
    public let address_zip_check: Verification?
    public let brand: Brand
    public let country: CountryCode
    public let currency: String?
    public let customer: String?
    public let cvc_check: Verification?
    public let default_for_currency: Bool?
    public let dynamic_last4: String?
    public let last4: String
    public let exp_year: Int
    public let exp_month: Int
    public let fingerprint: String
    public let funding: Funding?
    public let name: String?
    public let recipient: String?
    public let tokenization_method: TokenizationMethod?
    
    public init(node: Node) throws {
        
        guard try node.extract("object") == Card.type else {
            throw NodeError.unableToConvert(input: node, expectation: Card.type, path: ["object"])
        }

        id = try node.extract("id")
        address_city = try? node.extract("address_city")
        address_county = try? node.extract("address_county")
        address_line1 = try? node.extract("address_line1")
        address_line2 = try? node.extract("address_line2")
        address_line1_check = try? node.extract("address_line1_check")
        address_state = try? node.extract("address_state")
        address_zip = try? node.extract("address_zip")
        address_zip_check = try? node.extract("address_zip_check")
        brand = try node.extract("brand")
        country = try node.extract("country")
        currency = try? node.extract("currency")
        customer = try? node.extract("customer")
        cvc_check = try? node.extract("cvc_check")
        default_for_currency = try? node.extract("default_for_currency")
        dynamic_last4 = try? node.extract("dynamic_last4")
        last4 = try node.extract("last4")
        exp_year = try node.extract("exp_year")
        exp_month = try node.extract("exp_month")
        fingerprint = try node.extract("fingerprint")
        funding = try? node.extract("funding")
        name = try? node.extract("name")
        recipient = try? node.extract("recipient")
        tokenization_method = try? node.extract("tokenization_method")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node : [
            "id" : .string(id),
            "brand" : .string(brand.rawValue),
            "county" : .string(country.rawValue),
            "last4" : .string(last4),
            "exp_year" : .number(.int(exp_year)),
            "exp_month" : .number(.int(exp_month)),
            "fingerprint" : .string(fingerprint)
        ] as [String : Node]).add(objects: [
            "currency" : currency,
            "cvc_check" : cvc_check,
            "default_for_currency" : default_for_currency,
            "dynamic_last4" : dynamic_last4,
            "tokenization_method" : tokenization_method,
            "address_line1_check" : address_line1_check,
            "address_zip_check" : address_zip_check,
            "address_city" : address_city,
            "address_county" : address_county,
            "address_line1" : address_line1,
            "address_line2" : address_line2,
            "address_state" : address_state,
            "address_zip" : address_zip,
            "funding" : funding,
            "name" : name,
            "recipient" : recipient,
            "customer" : customer
        ])
    }
}
