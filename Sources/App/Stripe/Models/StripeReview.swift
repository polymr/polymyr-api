//
//  Review.swift
//  Stripe
//
//  Created by Hakon Hanesand on 1/1/17.
//
//

import Node
import Foundation

public enum ReviewReason: String, NodeConvertible {

    case rule
    case manual
    case approved
    case refunded
    case refunded_as_fraud
    case disputed
}

public final class StripeReview: NodeConvertible {

    static let type = "review"

    public let id: String
    public let charge: String
    public let created: Date
    public let livemode: Bool
    public let open: Bool
    public let reason: ReviewReason

    public required init(node: Node) throws {

        guard try node.get("object") == StripeReview.type else {
            throw NodeError.unableToConvert(input: node, expectation: StripeReview.type, path: ["object"])
        }

        id = try node.get("id")
        charge = try node.get("charge")
        created = try node.get("created")
        livemode = try node.get("livemode")
        open = try node.get("open")
        reason = try node.get("reason")
    }

    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node : [
            "id" : .string(id),
            "charge" : .string(charge),
            "created" : try created.makeNode(in: context),
            "livemode" : .bool(livemode),
            "open" : .bool(open),
            "reason" : try reason.makeNode(in: context)
        ] as [String : Node])
    }
}
