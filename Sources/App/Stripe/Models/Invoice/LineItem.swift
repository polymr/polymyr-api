//
//  LineItem.swift
//  Stripe
//
//  Created by Hakon Hanesand on 1/18/17.
//
//

import Foundation
import Node

public final class Period: NodeConvertible {
    
    public let start: Date
    public let end: Date
    
    public init(node: Node, in context: Context = EmptyNode) throws {
        start = try node.extract("start")
        end = try node.extract("end")
    }
    
    public func makeNode(context: Context = EmptyNode) throws -> Node {
        return try Node(node: [
            "start" : try start.makeNode(),
            "end" : try end.makeNode()
            ] as [String : Node])
    }
}

public enum LineItemType: String, NodeConvertible {
    
    case invoiceitem
    case subscription
}

public final class LineItem: NodeConvertible {
    
    static let type = "line_item"
    
    public let id: String
    public let amount: Int
    public let currency: Currency
    public let description: String?
    public let discountable: Bool
    public let livemode: Bool
    public let metadata: Node
    public let period: Period
    public let plan: Plan
    public let proration: Bool
    public let quantity: Int
    public let subscription: StripeSubscription
    public let subscription_item: String
    public let type: LineItemType
    
    public init(node: Node, in context: Context = EmptyNode) throws {
        guard try node.extract("object") == LineItem.type else {
            throw NodeError.unableToConvert(node: node, expected: LineItem.type)
        }
        
        id = try node.extract("id")
        amount = try node.extract("amount")
        currency = try node.extract("currency")
        description = try node.extract("description")
        discountable = try node.extract("discountable")
        livemode = try node.extract("livemode")
        metadata = try node.extract("metadata")
        period = try node.extract("period")
        plan = try node.extract("plan")
        proration = try node.extract("proration")
        quantity = try node.extract("quantity")
        subscription = try node.extract("subscription")
        subscription_item = try node.extract("subscription_item")
        type = try node.extract("type")
    }
    
    public func makeNode(context: Context = EmptyNode) throws -> Node {
        return try Node(node: [
            "id" : .string(id),
            "amount" : .number(.int(amount)),
            "currency" : try currency.makeNode(),
            "discountable" : .bool(discountable),
            "livemode" : .bool(livemode),
            "metadata" : metadata,
            "period" : try period.makeNode(),
            "plan" : try plan.makeNode(),
            "proration" : .bool(proration),
            "quantity" : .number(.int(quantity)),
            "subscription" : try subscription.makeNode(),
            "subscription_item" : .string(subscription_item),
            "type" : try type.makeNode()
            ] as [String : Node]).add(objects: [
                "description" : description
                ])
    }
}
