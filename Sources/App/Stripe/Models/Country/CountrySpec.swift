//
//  CountrySpec.swift
//  Stripe
//
//  Created by Hakon Hanesand on 1/18/17.
//
//

import Node
import Vapor

public enum CountryType: String, NodeConvertible {
    
    case at
    case au
    case be
    case ca
    case ch
    case de
    case dk
    case es
    case fi
    case fr
    case gb
    case hk
    case ie
    case it
    case jp
    case lu
    case nl
    case no
    case nz
    case pt
    case se
    case sg
    case us
    
    public init(node: Node) throws {
        guard let value = node.string else {
            throw Abort.custom(status: .internalServerError, message: "Expected \(String.self) for country code")
        }
        
        guard let _self = CountryType(rawValue: value.lowercased()) else {
            throw Abort.custom(status: .internalServerError, message: "Currency code \(value.lowercased()) doesn't match any known country codes.")
        }
        
        self = _self
    }
}

public final class Country: NodeConvertible {
    
    static let type = "country_spec"
    
    public let id: CountryType
    public let default_currency: Currency
    public let supported_bank_account_currencies: Node
    public let supported_payment_currencies: [Currency]
    public let supported_payment_methods: [String]
    public let verification_fields: CountryVerificationFields
    
    public init(node: Node) throws {
        
        guard try node.extract("object") == Country.type else {
            throw NodeError.unableToConvert(input: node, expectation: Country.type, path: ["object"])
        }
        
        id = try node.extract("id")
        default_currency = try node.extract("default_currency")
        supported_bank_account_currencies = try node.extract("supported_bank_account_currencies")
        supported_payment_currencies = try node.extract("supported_payment_currencies")
        supported_payment_methods = try node.extract("supported_payment_methods")
        verification_fields = try node.extract("verification_fields")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "id" : try id.makeNode(in: context),
            "default_currency" : try default_currency.makeNode(in: context),
            "supported_bank_account_currencies" : supported_bank_account_currencies,
            "supported_payment_currencies" : .array(supported_payment_currencies.map { Node.string($0.rawValue) } ),
            "supported_payment_methods" : .array(supported_payment_methods.map { Node.string($0) } ),
            "verification_fields" : verification_fields.makeNode(in: context)
        ] as [String : Node])
    }
}
