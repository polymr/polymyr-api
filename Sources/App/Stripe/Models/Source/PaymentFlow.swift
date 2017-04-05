//
//  PaymentFlow.swift
//  Stripe
//
//  Created by Hakon Hanesand on 1/18/17.
//
//

import Node

public final class Owner: NodeConvertible {
    
    public let address: Address
    public let email: String
    public let name: String
    public let phone: String
    public let verified_address: Address
    public let verified_email: String
    public let verified_name: String
    public let verified_phone: String
    
    public init(node: Node) throws {
        address = try node.extract("address")
        email = try node.extract("email")
        name = try node.extract("name")
        phone = try node.extract("phone")
        verified_address = try node.extract("verified_address")
        verified_email = try node.extract("verified_email")
        verified_name = try node.extract("verified_name")
        verified_phone = try node.extract("verified_phone")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "address" : address.makeNode(in: context),
            "email" : .string(email),
            "name" : .string(name),
            "phone" : .string(phone),
            "verified_address" : verified_address.makeNode(in: context),
            "verified_email" : .string(verified_email),
            "verified_name" : .string(verified_name),
            "verified_phone" : .string(verified_phone)
        ] as [String : Node])
    }
}

public final class Reciever: NodeConvertible {
    
    public let address: String
    public let amount_charged: String
    public let amount_received: String
    public let amount_returned: String
    public let refund_attributes_method: String?
    public let refund_attributes_status: String?
    
    public init(node: Node) throws {
        address = try node.extract("address")
        amount_charged = try node.extract("amount_charged")
        amount_received = try node.extract("amount_received")
        amount_returned = try node.extract("amount_returned")
        refund_attributes_method = try node.extract("refund_attributes_method")
        refund_attributes_status = try node.extract("refund_attributes_status")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "address" : .string(address),
            "amount_charged" : .string(amount_charged),
            "amount_received" : .string(amount_received),
            "amount_returned" : .string(amount_returned)
        ] as [String : Node]).add(objects: [
            "refund_attributes_method" : refund_attributes_method,
            "refund_attributes_status" : refund_attributes_status
        ])
    }
}

public enum Usage: String, NodeConvertible {
    case reusable
    case singleUse = "single-use"
}


public enum SourceStatus: String, NodeConvertible {
    case pending
    case chargeable
    case consumed
    case canceled
}

public enum PaymentFlow: String, NodeConvertible {
    case redirect
    case receiver
    case verification
    case none
}

public final class VerificationInformation: NodeConvertible {
    
    public let attempts_remaining: Int
    public let status: SourceStatus
    
    public init(node: Node) throws {
        attempts_remaining = try node.extract("attempts_remaining")
        status = try node.extract("status")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "attempts_remaining" : .number(.int(attempts_remaining)),
            "status" : .string(status.rawValue)
        ] as [String : Node])
    }
}
