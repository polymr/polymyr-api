//
//  Coupon.swift
//  Stripe
//
//  Created by Hakon Hanesand on 12/2/16.
//
//

import Node
import Foundation

public enum Duration: String, NodeConvertible {
    
    case forever
    case once
    case repeating
}

public final class StripeCoupon: NodeConvertible {
    
    static let type = "coupon"
    
    public let id: String
    public let amount_off: Int?
    public let created: Date
    public let currency: String?
    public let duration: Duration
    public let duration_in_months: Int?
    public let livemode: Bool
    public let max_redemptions: Int
    public let percent_off: Int
    public let redeem_by: Date
    public let times_redeemed: Int
    public let valid: Bool
    
    public init(node: Node) throws {
        guard try node.get("object") == StripeCoupon.type else {
            throw NodeError.unableToConvert(input: node, expectation: StripeCoupon.type, path: ["object"])
        }
        
        id = try node.get("id")
        amount_off = try node.get("amount_off")
        created = try node.get("created")
        currency = try node.get("currency")
        duration = try node.get("duration")
        duration_in_months = try node.get("duration_in_months")
        livemode = try node.get("livemode")
        max_redemptions = try node.get("max_redemptions")
        percent_off = try node.get("percent_off")
        redeem_by = try node.get("redeem_by")
        times_redeemed = try node.get("times_redeemed")
        valid = try node.get("valid")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "id" : .string(id),
            "created" : .number(.double(created.timeIntervalSince1970)),
            "duration" : try duration.makeNode(in: context),
            "livemode" : .bool(livemode),
            "max_redemptions" : .number(.int(max_redemptions)),
            "percent_off" : .number(.int(percent_off)),
            "redeem_by" : .number(.double(redeem_by.timeIntervalSince1970)),
            "times_redeemed" : .number(.int(times_redeemed)),
            "valid" : .bool(valid)
        ] as [String : Node]).add(objects: [
            "amount_off" : amount_off,
            "currency" : currency,
            "duration_in_months" : duration_in_months
        ])
    }
}
