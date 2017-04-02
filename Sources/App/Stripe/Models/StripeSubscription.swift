//
//  Subscription.swift
//  Stripe
//
//  Created by Hakon Hanesand on 12/2/16.
//
//

import Node
import Foundation

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
    
    public init(node: Node) throws {
        
        guard try node.get("object") == StripeSubscription.type else {
            throw NodeError.unableToConvert(input: node, expectation: StripeSubscription.type, path: ["object"])
        }
        
        id = try node.get("id")
        application_fee_percent = try node.get("application_fee_percent")
        cancel_at_period_end = try node.get("cancel_at_period_end")
        canceled_at = try node.get("canceled_at")
        created = try node.get("created")
        current_period_end = try node.get("current_period_end")
        current_period_start = try node.get("current_period_start")
        customer = try node.get("customer")
        discount = try node.get("discount")
        ended_at = try node.get("ended_at")
        livemode = try node.get("livemode")
        plan = try node.get("plan")
        quantity = try node.get("quantity")
        start = try node.get("start")
        status = try node.get("status")
        tax_percent = try node.get("tax_percent")
        trial_end = try node.get("trial_end")
        trial_start = try node.get("trial_start")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "id" : .string(id),
            "cancel_at_period_end" : .bool(cancel_at_period_end),
            "created" : .number(.double(created.timeIntervalSince1970)),
            "current_period_end" : .number(.double(current_period_end.timeIntervalSince1970)),
            "current_period_start" : .number(.double(current_period_start.timeIntervalSince1970)),
            "customer" : .string(customer),
            "livemode" : .bool(livemode),
            "plan" : plan.makeNode(in: context),
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
