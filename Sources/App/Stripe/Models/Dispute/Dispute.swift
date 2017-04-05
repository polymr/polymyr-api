//
//  Dispute.swift
//  Stripe
//
//  Created by Hakon Hanesand on 1/1/17.
//
//

import Node
import Foundation

public final class DisputeInfo: NodeConvertible {

    public let due_by: Date
    public let has_evidence: Bool
    public let past_due: Bool
    public let submission_count: Int

    public init(node: Node) throws {

        due_by = try node.extract("due_by")
        has_evidence = try node.extract("has_evidence")
        past_due = try node.extract("past_due")
        submission_count = try node.extract("submission_count")
    }

    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "due_by" : try due_by.makeNode(in: context),
            "has_evidence" : .bool(has_evidence),
            "past_due" : .bool(past_due),
            "submission_count" : .number(.int(submission_count))
        ] as [String : Node])
    }
}

public enum DisputeReason: String, NodeConvertible {

    case duplicate
    case fraudulent
    case subscription_canceled
    case product_unacceptable
    case product_not_received
    case unrecognized
    case credit_not_processed
    case general
    case goods_services_returned_or_refused
    case goods_services_cancelled
    case incorrect_account_details
    case insufficient_funds
    case bank_cannot_process
    case debit_not_authorized
}

public enum DisputeStatus: String, NodeConvertible {

    case warning_needs_response
    case warning_under_review
    case warning_closed
    case needs_response
    case response_disabled
    case under_review
    case charge_refunded
    case won
    case lost
}

public final class Dispute: NodeConvertible {

    static let type = "dispute"

    public let amount: Int
    public let balance_transactions: Node
    public let charge: String
    public let created: Date
    public let currency: Currency
    public let evidence: DisputeEvidence
    public let evidence_details: DisputeInfo
    public let is_charge_refundable: Bool
    public let livemode: Bool
    public let reason: DisputeReason
    public let status: DisputeStatus

    public required init(node: Node) throws {

        guard try node.extract("object") == Dispute.type else {
            throw NodeError.unableToConvert(input: node, expectation: Dispute.type, path: ["object"])
        }

        amount = try node.extract("amount")
        balance_transactions = try node.extract("balance_transactions")
        charge = try node.extract("charge")
        created = try node.extract("created")
        currency = try node.extract("currency")
        evidence = try node.extract("evidence")
        evidence_details = try node.extract("evidence_details")
        is_charge_refundable = try node.extract("is_charge_refundable")
        livemode = try node.extract("livemode")
        reason = try node.extract("reason")
        status = try node.extract("status")
    }

    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node : [
            "amount" : .number(.int(amount)),
            "balance_transactions" : balance_transactions,
            "charge" : .string(charge),
            "created" : try created.makeNode(in: context),
            "currency" : try currency.makeNode(in: context),
            "evidence" : try evidence.makeNode(in: context),
            "evidence_details" : try evidence_details.makeNode(in: context),
            "is_charge_refundable" : .bool(is_charge_refundable),
            "livemode" : .bool(livemode),
            "reason" : try reason.makeNode(in: context),
            "status" : try status.makeNode(in: context)
        ] as [String : Node])
    }
}
