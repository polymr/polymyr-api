//
//  Review.swift
//  Stripe
//
//  Created by Hakon Hanesand on 1/1/17.
//
//

import Foundation
import Node

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

    public required init(node: Node, in context: Context = EmptyNode) throws {

        guard try node.extract("object") == StripeReview.type else {
            throw NodeError.unableToConvert(node: node, expected: StripeReview.type)
        }

        id = try node.extract("id")
        charge = try node.extract("charge")
        created = try node.extract("created")
        livemode = try node.extract("livemode")
        open = try node.extract("open")
        reason = try node.extract("reason")
    }

    public func makeNode(context: Context = EmptyNode) throws -> Node {
        return try Node(node : [
            "id" : .string(id),
            "charge" : .string(charge),
            "created" : try created.makeNode(),
            "livemode" : .bool(livemode),
            "open" : .bool(open),
            "reason" : try reason.makeNode()
        ] as [String : Node])
    }
}
