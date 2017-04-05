//
//  Token.swift
//  Stripe
//
//  Created by Hakon Hanesand on 12/23/16.
//
//

import Node
import Foundation

public final class Token: NodeConvertible {

    static let type = "token"

    public let id: String
    public let client_ip: String
    public let created: Date
    public let livemode: Bool
    public let type: String
    public let used: Bool
    public let card: Card

    public required init(node: Node) throws {
        guard try node.extract("object") == Token.type else {
            throw NodeError.unableToConvert(input: node, expectation: Token.type, path: ["object"])
        }

        id = try node.extract("id")
        client_ip = try node.extract("client_ip")
        created = try node.extract("created")
        livemode = try node.extract("livemode")
        type = try node.extract("type")
        used = try node.extract("used")
        card = try node.extract("card")
    }

    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node : [
            "id" : .string(id),
            "client_ip" : .string(client_ip),
            "created" : try created.makeNode(in: context),
            "livemode" : .bool(livemode),
            "type" : .string(type),
            "used" : .bool(used),
            "card" : card.makeNode(in: context)
        ] as [String : Node])
    }
}
