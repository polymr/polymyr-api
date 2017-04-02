//
//  Customer.swift
//  Stripe
//
//  Created by Hakon Hanesand on 12/2/16.
//
//

import Node
import Vapor
import Foundation

public final class StripeCustomer: NodeConvertible {
    
    static let type = "customer"
    
    public let id: String
    public let account_balance: Int
    public let created: Date
    public let currency: Currency?
    public let default_source: String
    public let delinquent: Bool
    public let metadata: Node
    public let description: String?
    public let discount: Discount?
    public let email: String?
    public let livemode: Bool
    public let sources: [Card]
    public let subscriptions: [StripeSubscription]
    
    public init(node: Node) throws {
        
        guard try node.get("object") == StripeCustomer.type else {
            throw NodeError.unableToConvert(input: node, expectation: StripeCustomer.type, path: ["object"])
        }
        
        id = try node.get("id")
        account_balance = try node.get("account_balance")
        created = try node.get("created")
        currency = try node.get("currency")
        default_source = try node.get("default_source")
        delinquent = try node.get("delinquent")
        description = try node.get("description")
        discount = try node.get("discount")
        email = try node.get("email")
        livemode = try node.get("livemode")
        sources = try node.extractList("sources")
        subscriptions = try node.extractList("subscriptions")
        metadata = try node.get("metadata")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "id" : .string(id),
            "account_balance" : .number(.int(account_balance)),
            "created" : .number(.double(created.timeIntervalSince1970)),
            "default_source" : .string(default_source),
            "delinquent" : .bool(delinquent),
            "livemode" : .bool(livemode),
            "sources" :  .array(sources.map { try $0.makeNode(in: context) }),
            "subscriptions" : .array(subscriptions.map { try $0.makeNode(in: context) }),
            "metadata" : metadata
        ] as [String : Node]).add(objects: [
            "discount" : discount,
            "currency" : currency,
            "description" : description,
            "email" : email
        ])
    }
}
