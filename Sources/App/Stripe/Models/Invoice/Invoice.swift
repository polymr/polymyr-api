//
//  Invoice.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/18/17.
//
//

import Node
import Foundation

public final class Invoice: NodeConvertible {
    
    static let type = "invoice"
    
    public let id: String
    public let amount_due: Int
    public let application_fee: Int?
    public let attempt_count: Int
    public let attempted: Bool
    public let charge: String
    public let closed: Bool
    public let currency: Currency
    public let customer: String
    public let date: Date
    public let description: String?
    public let discount: Discount
    public let ending_balance: Int?
    public let forgiven: Bool
    public let lines: [LineItem]
    public let livemode: Bool
    public let metadata: Node
    public let next_payment_attempt: Date
    public let paid: Bool
    public let period_end: Date
    public let period_start: Date
    public let receipt_number: String?
    public let starting_balance: Int?
    public let statement_descriptor: String?
    public let subscription: String
    public let subtotal: Int
    public let tax: Int?
    public let tax_percent: Double?
    public let total: Int
    public let webhooks_delivered_at: Date
    
    public init(node: Node) throws {
        guard try node.get("object") == Invoice.type else {
            throw NodeError.unableToConvert(input: node, expectation: Invoice.type, path: ["object"])
        }
        
        id = try node.get("id")
        amount_due = try node.get("amount_due")
        application_fee = try node.get("application_fee")
        attempt_count = try node.get("attempt_count")
        attempted = try node.get("attempted")
        charge = try node.get("charge")
        closed = try node.get("closed")
        currency = try node.get("currency")
        customer = try node.get("customer")
        date = try node.get("date")
        description = try node.get("description")
        discount = try node.get("discount")
        ending_balance = try node.get("ending_balance")
        forgiven = try node.get("forgiven")
        lines = try node.get("lines")
        livemode = try node.get("livemode")
        metadata = try node.get("metadata")
        next_payment_attempt = try node.get("next_payment_attempt")
        paid = try node.get("paid")
        period_end = try node.get("period_end")
        period_start = try node.get("period_start")
        receipt_number = try node.get("receipt_number")
        starting_balance = try node.get("starting_balance")
        statement_descriptor = try node.get("statement_descriptor")
        subscription = try node.get("subscription")
        subtotal = try node.get("subtotal")
        tax = try node.get("tax")
        tax_percent = try node.get("tax_percent")
        total = try node.get("total")
        webhooks_delivered_at = try node.get("webhooks_delivered_at")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "id" : .string(id),
            "amount_due" : .number(.int(amount_due)),
            "attempt_count" : .number(.int(attempt_count)),
            "attempted" : .bool(attempted),
            "charge" : .string(charge),
            "closed" : .bool(closed),
            "currency" : try currency.makeNode(in: context),
            "customer" : .string(customer),
            "date" : try date.makeNode(in: context),
            "discount" : try discount.makeNode(in: context),
            "forgiven" : .bool(forgiven),
            "lines" : try .array(lines.map { try $0.makeNode(in: context) }),
            "livemode" : .bool(livemode),
            "metadata" : metadata,
            "next_payment_attempt" : try next_payment_attempt.makeNode(in: context),
            "paid" : .bool(paid),
            "period_end" : try period_end.makeNode(in: context),
            "period_start" : try period_start.makeNode(in: context),
            "subscription" : .string(subscription),
            "subtotal" : .number(.int(subtotal)),
            "total" : .number(.int(total)),
            "webhooks_delivered_at" : try webhooks_delivered_at.makeNode(in: context)
        ] as [String: Node]).add(objects: [
            "application_fee" : application_fee,
            "description" : description,
            "receipt_number" : receipt_number,
            "starting_balance" : starting_balance,
            "statement_descriptor" : statement_descriptor,
            "tax" : tax,
            "tax_percent" : tax_percent
        ])
    }
}
