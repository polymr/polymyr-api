//
//  Discount.swift
//  Stripe
//
//  Created by Hakon Hanesand on 12/2/16.
//
//

import Foundation
import Node

public final class Discount: NodeConvertible {
    
    static let type = "discount"
    
    public let coupon: StripeCoupon
    public let customer: String
    public let end: Date
    public let start: Date
    public let subscription: String
    
    public init(node: Node, in context: Context = EmptyNode) throws {
        
        guard try node.extract("object") == Discount.type else {
            throw NodeError.unableToConvert(node: node, expected: Discount.type)
        }
        
        coupon = try node.extract("coupon")
        customer = try node.extract("customer")
        end = try node.extract("end")
        start = try node.extract("start")
        subscription = try node.extract("subscription")
    }
    
    public func makeNode(context: Context = EmptyNode) throws -> Node {
        return try Node(node: [
            "coupon" : coupon.makeNode(),
            "customer" : .string(customer),
            "end" : .number(.double(end.timeIntervalSince1970)),
            "start" : .number(.double(start.timeIntervalSince1970)),
            "subscription" : .string(subscription)
        ] as [String : Node])
    }
}
