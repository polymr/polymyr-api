//
//  LineItem.swift
//  Stripe
//
//  Created by Hakon Hanesand on 1/18/17.
//
//

import Node
import Foundation

public final class Period: NodeConvertible {
    
    public let start: Date
    public let end: Date
    
    public init(node: Node) throws {
        start = try node.get("start")
        end = try node.get("end")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "start" : try start.makeNode(in: context),
            "end" : try end.makeNode(in: context)
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
    
    public init(node: Node) throws {
        guard try node.get("object") == LineItem.type else {
            throw NodeError.unableToConvert(input: node, expectation: LineItem.type, path: ["object"])
        }
        
        id = try node.get("id")
        amount = try node.get("amount")
        currency = try node.get("currency")
        description = try node.get("description")
        discountable = try node.get("discountable")
        livemode = try node.get("livemode")
        metadata = try node.get("metadata")
        period = try node.get("period")
        plan = try node.get("plan")
        proration = try node.get("proration")
        quantity = try node.get("quantity")
        subscription = try node.get("subscription")
        subscription_item = try node.get("subscription_item")
        type = try node.get("type")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "id" : .string(id),
            "amount" : .number(.int(amount)),
            "currency" : try currency.makeNode(in: context),
            "discountable" : .bool(discountable),
            "livemode" : .bool(livemode),
            "metadata" : metadata,
            "period" : try period.makeNode(in: context),
            "plan" : try plan.makeNode(in: context),
            "proration" : .bool(proration),
            "quantity" : .number(.int(quantity)),
            "subscription" : try subscription.makeNode(in: context),
            "subscription_item" : .string(subscription_item),
            "type" : try type.makeNode(in: context)
            ] as [String : Node]).add(objects: [
                "description" : description
                ])
    }
}
