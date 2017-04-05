//
//  Discount.swift
//  Stripe
//
//  Created by Hakon Hanesand on 12/2/16.
//
//

import Node
import Foundation

public final class Discount: NodeConvertible {
    
    static let type = "discount"
    
    public let coupon: StripeCoupon
    public let customer: String
    public let end: Date
    public let start: Date
    public let subscription: String
    
    public init(node: Node) throws {
        
        guard try node.extract("object") == Discount.type else {
            throw NodeError.unableToConvert(input: node, expectation: Discount.type, path: ["object"])
        }
        
        coupon = try node.extract("coupon")
        customer = try node.extract("customer")
        end = try node.extract("end")
        start = try node.extract("start")
        subscription = try node.extract("subscription")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "coupon" : coupon.makeNode(in: context),
            "customer" : .string(customer),
            "end" : .number(.double(end.timeIntervalSince1970)),
            "start" : .number(.double(start.timeIntervalSince1970)),
            "subscription" : .string(subscription)
        ] as [String : Node])
    }
}
