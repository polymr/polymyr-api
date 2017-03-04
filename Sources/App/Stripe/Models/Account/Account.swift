//
//  Account.swift
//  Stripe
//
//  Created by Hakon Hanesand on 1/2/17.
//
//

import Foundation
import Node
import Vapor

public final class DeclineChargeRules: NodeConvertible {
    
    public let avs_failure: Bool
    public let cvc_failure: Bool
    
    public required init(node: Node, in context: Context = EmptyNode) throws {
        avs_failure = try node.extract("avs_failure")
        cvc_failure = try node.extract("cvc_failure")
    }
    
    public func makeNode(context: Context = EmptyNode) throws -> Node {
        return try Node(node: [
            "avs_failure" : .bool(avs_failure),
            "cvc_failure" : .bool(cvc_failure)
        ] as [String : Node])
    }
}

public final class Document: NodeConvertible {

    public let id: String
    public let created: Date
    public let size: Int

    public required init(node: Node, in context: Context = EmptyNode) throws {
        id = try node.extract("id")
        created = try node.extract("created")
        size = try node.extract("size")
    }

    public func makeNode(context: Context = EmptyNode) throws -> Node {
        return try Node(node: [
            "id" : .string(id),
            "created" : try created.makeNode(),
            "size" : .number(.int(size))
        ] as [String : Node])
    }
}

public final class DateOfBirth: NodeConvertible {

    public let day: Int?
    public let month: Int?
    public let year: Int?

    public required init(node: Node, in context: Context) throws {
        day = try node.extract("day")
        month = try node.extract("month")
        year = try node.extract("year")
    }

    public func makeNode(context: Context = EmptyNode) throws -> Node {
        return try Node(node: [:]).add(objects: [
            "day" : day,
            "month" : month,
            "year" : year
        ])
    }
}

public final class TermsOfServiceAgreement: NodeConvertible {

    public let date: Date?
    public let ip: String?
    public let user_agent: String?

    public required init(node: Node, in context: Context) throws {
        date = try node.extract("date")
        ip = try node.extract("ip")
        user_agent = try node.extract("user_agent")
    }

    public func makeNode(context: Context = EmptyNode) throws -> Node {
        return try Node(node: [:]).add(objects: [
            "date" : date,
            "ip" : ip,
            "user_agent" : user_agent
        ])
    }
}

public final class TransferSchedule: NodeConvertible {

    public let delay_days: Int
    public let interval: Interval

    public required init(node: Node, in context: Context) throws {
        delay_days = try node.extract("delay_days")
        interval = try node.extract("interval")
    }

    public func makeNode(context: Context = EmptyNode) throws -> Node {
        return try Node(node: [
            "delay_days" : .number(.int(delay_days)),
            "interval" : try interval.makeNode()
        ] as [String : Node])
    }
}

public final class Keys: NodeConvertible {
    
    public let secret: String
    public let publishable: String
    
    public required init(node: Node, in context: Context) throws {
        secret = try node.extract("secret")
        publishable = try node.extract("publishable")
    }
    
    public func makeNode(context: Context = EmptyNode) throws -> Node {
        return try Node(node: [
            "secret" : .string(secret),
            "publishable" : .string(publishable)
        ] as [String : Node])
    }
}

extension Sequence where Iterator.Element == (key: String, value: Node) {
    
    func group(with separator: String = ".") throws -> Node {
        guard let dictionary = self as? [String : Node] else {
            throw Abort.custom(status: .internalServerError, message: "Unable to cast to [String: Node].")
        }
        
        var result = Node.object([:])
        dictionary.forEach { result[$0.components(separatedBy: separator)] = $1 }
        return result
    }
}

public final class StripeAccount: NodeConvertible {
    
    static let type = "account"

    public let id: String
    public let business_logo: String?
    public let business_name: String?
    public let business_url: String?
    public let charges_enabled: Bool
    public let country: CountryType
    public let debit_negative_balances: Bool
    public let decline_charge_on: DeclineChargeRules
    public let default_currency: Currency
    public let details_submitted: Bool
    public let display_name: String?
    public let email: String
    public let external_accounts: [ExternalAccount]
    public let legal_entity: LegalEntity
    public let managed: Bool
    public let product_description: String?
    public let statement_descriptor: String?
    public let support_email: String?
    public let support_phone: String?
    public let timezone: String
    public let tos_acceptance: TermsOfServiceAgreement
    public let transfer_schedule: TransferSchedule
    public let transfer_statement_descriptor: String?
    public let transfers_enabled: Bool
    public let verification: IdentityVerification
    public let keys: Keys?
    public let metadata: Node

    public required init(node: Node, in context: Context) throws {
        
        guard try node.extract("object") == StripeAccount.type else {
            throw NodeError.unableToConvert(node: node, expected: StripeAccount.type)
        }
        
        id = try node.extract("id")
        business_logo = try node.extract("business_logo")
        business_name = try node.extract("business_name")
        business_url = try node.extract("business_url")
        charges_enabled = try node.extract("charges_enabled")
        country = try node.extract("country")
        debit_negative_balances = try node.extract("debit_negative_balances")
        decline_charge_on = try node.extract("decline_charge_on")
        default_currency = try node.extract("default_currency")
        details_submitted = try node.extract("details_submitted")
        display_name = try node.extract("display_name")
        email = try node.extract("email")
        external_accounts = try node.extractList("external_accounts")
        legal_entity = try node.extract("legal_entity")
        managed = try node.extract("managed")
        product_description = try node.extract("product_description")
        statement_descriptor = try node.extract("statement_descriptor")
        support_email = try node.extract("support_email")
        support_phone = try node.extract("support_phone")
        timezone = try node.extract("timezone")
        tos_acceptance = try node.extract("tos_acceptance")
        transfer_schedule = try node.extract("transfer_schedule")
        transfer_statement_descriptor = try node.extract("transfer_statement_descriptor")
        transfers_enabled = try node.extract("transfers_enabled")
        verification = try node.extract("verification")
        keys = try node.extract("keys")
        metadata = node["metadata"] ?? EmptyNode
    }

    public func makeNode(context: Context = EmptyNode) throws -> Node {
        return try Node(node: [
            "id" : .string(id),
            "charges_enabled" : .bool(charges_enabled),
            "country" : try country.makeNode(),
            "debit_negative_balances" : .bool(debit_negative_balances),
            "decline_charge_on" : try decline_charge_on.makeNode(),
            "default_currency" : try default_currency.makeNode(),
            "details_submitted" : .bool(details_submitted),
            "email" : .string(email),
            "external_accounts" : try .array(external_accounts.map { try $0.makeNode() }),
            "legal_entity" : try legal_entity.makeNode(),
            "managed" : .bool(managed),
            "timezone" : .string(timezone),
            "tos_acceptance" : try tos_acceptance.makeNode(),
            "transfer_schedule" : try transfer_schedule.makeNode(),
            "transfers_enabled" : .bool(transfers_enabled),
            "verification" : try verification.makeNode(),
            "metadata" : metadata
        ] as [String : Node]).add(objects: [
            "business_logo" : business_logo,
            "business_name" : business_name,
            "business_url" : business_url,
            "product_description" : product_description,
            "statement_descriptor" : statement_descriptor,
            "support_email" : support_email,
            "support_phone" : support_phone,
            "transfer_statement_descriptor" : transfer_statement_descriptor,
            "display_name" : display_name,
            "keys" : keys
        ])
    }
    
    public func filteredNeededFieldsWithCombinedDateOfBirth(filtering prefix: String = "tos_acceptance") -> [String] {
        var fieldsNeeded = verification.fields_needed.filter { !$0.hasPrefix(prefix) }
        
        if fieldsNeeded.contains(where: { $0.contains("dob") }) {
            let keysToRemove = ["legal_entity.dob.day", "legal_entity.dob.month", "legal_entity.dob.year"]
            fieldsNeeded = fieldsNeeded.filter { !keysToRemove.contains($0) }
            fieldsNeeded.append("legal_entity.dob")
        }

        return fieldsNeeded
    }
    
    public func descriptionsForNeededFields() throws -> Node {
        var descriptions: [Node] = []
        
        try filteredNeededFieldsWithCombinedDateOfBirth().forEach {
            descriptions.append(contentsOf: try description(for: $0))
        }
        
        return .array(descriptions)
    }
    
    private func description(for field: String) throws -> [Node] {
        switch field {
        case "external_account":
            return ExternalAccount.descriptionsForNeededFields(in: country, for: field)
            
        case let field where field.hasPrefix("legal_entity"):
            return [.object(LegalEntity.descriptionForNeededFields(in: country, for: field))]
            
        case "tos_acceptance.date": fallthrough
        case "tos_acceptance.ip": fallthrough
        default:
            return [.string(field)]
        }
    }
}
