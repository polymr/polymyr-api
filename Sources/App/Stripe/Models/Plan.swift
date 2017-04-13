//
//  Plan.swift
//  Stripe
//
//  Created by Hakon Hanesand on 12/2/16.
//
//

import Node
import Foundation

public enum Interval: String, NodeConvertible {
    case day = "daily"
    case week
    case month
    case year
}

public final class Plan: NodeConvertible {
    
    static let type = "plan"
    
    public let id: String
    public let amount: Int
    public let created: Date
    public let currency: Currency
    public let interval: Interval
    public let interval_count: Int
    public let livemode: Bool
    public let name: String
    public let statement_descriptor: String?
    public let trial_period_days: Int?
    
    public init(node: Node) throws {
        
        guard try node.extract("object") == Plan.type else {
            throw NodeError.unableToConvert(input: node, expectation: Plan.type, path: ["object"])
        }
        
        id = try node.extract("id")
        amount = try node.extract("amount")
        created = try node.extract("created")
        currency = try node.extract("currency")
        interval = try node.extract("interval")
        interval_count = try node.extract("interval_count")
        livemode = try node.extract("livemode")
        name = try node.extract("name")
        statement_descriptor = try? node.extract("statement_descriptor")
        trial_period_days = try? node.extract("trial_period_days")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "id" : .string(id),
            "amount" : .number(.int(amount)),
            "created" : .number(.double(created.timeIntervalSince1970)),
            "currency" : .string(currency.rawValue),
            "interval" : .string(interval.rawValue),
            "interval_count" : .number(.int(interval_count)),
            "livemode" : .bool(livemode),
            "name" : .string(name),
        ] as [String : Node]).add(objects: [
            "trial_period_days" : trial_period_days,
            "statement_descriptor" : statement_descriptor
        ])
    }
}
