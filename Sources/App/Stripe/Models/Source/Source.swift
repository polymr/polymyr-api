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
        
        guard try node.extract("object") == Source.type else {
            throw NodeError.unableToConvert(input: node, expectation: Source.type, path: ["object"])
        }
        
        id = try node.extract("id")
        amount = try node.extract("amount")
        client_secret = try node.extract("client_secret")
        created = try node.extract("created")
        currency = try node.extract("currency")
        flow = try node.extract("flow")
        livemode = try node.extract("livemode")
        owner = try node.extract("owner")
        receiver = try node.extract("receiver")
        status = try node.extract("status")
        type = try node.extract("type")
        usage = try node.extract("usage")
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
