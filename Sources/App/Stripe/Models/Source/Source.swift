//
//  Source.swift
//  Stripe
//
//  Created by Hakon Hanesand on 12/2/16.
//
//

import Node
import Foundation

public final class Source: NodeConvertible {
    
    static let type = "source"
    
    public let id: String
    public let amount: Int
    public let client_secret: String
    public let created: Date
    public let currency: Currency
    public let flow: PaymentFlow
    public let livemode: Bool
    public let owner: Owner
    public let receiver: Reciever?
    public let status: SourceStatus
    public let type: String
    public let usage: Usage
    
    public init(node: Node) throws {
        
        guard try node.get("object") == Source.type else {
            throw NodeError.unableToConvert(input: node, expectation: Source.type, path: ["object"])
        }
        
        id = try node.get("id")
        amount = try node.get("amount")
        client_secret = try node.get("client_secret")
        created = try node.get("created")
        currency = try node.get("currency")
        flow = try node.get("flow")
        livemode = try node.get("livemode")
        owner = try node.get("owner")
        receiver = try node.get("receiver")
        status = try node.get("status")
        type = try node.get("type")
        usage = try node.get("usage")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "id" : .string(id),
            "amount" : .number(.int(amount)),
            "client_secret" : .string(client_secret),
            "created" : .number(.double(created.timeIntervalSince1970)),
            "currency" : .string(currency.rawValue),
            "flow" : .string(flow.rawValue),
            "livemode" : .bool(livemode),
            "owner" : owner.makeNode(in: context),
            
            "status" : .string(status.rawValue),
            "type" : .string(type),
            "usage" : .string(usage.rawValue)
        ] as [String : Node]).add(name: "receiver", node: receiver?.makeNode(in: context))
    }
}
