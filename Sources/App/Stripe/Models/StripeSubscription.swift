//
//  Subscription.swift
//  Stripe
//
//  Created by Hakon Hanesand on 12/2/16.
//
//

import Foundation
import Node

public enum SubscriptionStatus: String, NodeConvertible {
    
    case trialing
    case active
    case pastDue = "past_due"
    case canceled
    case unpaid
}

public final class StripeSubscription: NodeConvertible {
    
    static let type = "subscription"
    
    public let id: String
    public let application_fee_percent: Double?
    public let cancel_at_period_end: Bool
    public let canceled_at: Date?
    public let created: Date
    public let current_period_end: Date
    public let current_period_start: Date
    public let customer: String
    public let discount: String?
    public let ended_at: Date?
    public let livemode: Bool
    public let plan: Plan
    public let quantity: Int
    public let start: Date
    public let status: SubscriptionStatus
    public let tax_percent: Double?
    public let trial_end: Date?
    public let trial_start: Date?
    
    public init(node: Node, in context: Context = EmptyNode) throws {
        
        guard try node.extract("object") == StripeSubscription.type else {
            throw NodeError.unableToConvert(node: node, expected: StripeSubscription.type)
        }
        
        id = try node.extract("id")
        application_fee_percent = try node.extract("application_fee_percent")
        cancel_at_period_end = try node.extract("cancel_at_period_end")
        canceled_at = try node.extract("canceled_at")
        created = try node.extract("created")
        current_period_end = try node.extract("current_period_end")
        current_period_start = try node.extract("current_period_start")
        customer = try node.extract("customer")
        discount = try node.extract("discount")
        ended_at = try node.extract("ended_at")
        livemode = try node.extract("livemode")
        plan = try node.extract("plan")
        quantity = try node.extract("quantity")
        start = try node.extract("start")
        status = try node.extract("status")
        tax_percent = try node.extract("tax_percent")
        trial_end = try node.extract("trial_end")
        trial_start = try node.extract("trial_start")
    }
    
    public func makeNode(context: Context = EmptyNode) throws -> Node {
        return try Node(node: [
            "id" : .string(id),
            "cancel_at_period_end" : .bool(cancel_at_period_end),
            "created" : .number(.double(created.timeIntervalSince1970)),
            "current_period_end" : .number(.double(current_period_end.timeIntervalSince1970)),
            "current_period_start" : .number(.double(current_period_start.timeIntervalSince1970)),
            "customer" : .string(customer),
            "livemode" : .bool(livemode),
            "plan" : plan.makeNode(),
            "quantity" : .number(.int(quantity)),
            "start" : .number(.double(start.timeIntervalSince1970)),
            "status" : .string(status.rawValue),
        ] as [String : Node]).add(objects: [
            "canceled_at" : canceled_at,
            "ended_at" : ended_at,
            "tax_percent" : tax_percent,
            "trial_end" : trial_end,
            "trial_start" : trial_start,
            "application_fee_percent" : application_fee_percent,
            "discount" : discount
        ])
    }
}
