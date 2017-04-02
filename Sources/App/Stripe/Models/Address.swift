//
//  Address.swift
//  Stripe
//
//  Created by Hakon Hanesand on 1/18/17.
//
//

import Node

public final class Address: NodeConvertible {
    
    public let city: String?
    public let country: CountryType
    public let line1: String?
    public let line2: String?
    public let postal_code: String?
    public let state: String?
    
    public init(node: Node) throws {
        city = try node.get("city")
        country = try node.get("country")
        line1 = try node.get("line1")
        line2 = try node.get("line2")
        postal_code = try node.get("postal_code")
        state = try node.get("state")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "country" : try country.makeNode(in: context),
        ] as [String : Node]).add(objects: [
            "city" : city,
            "line1" : line1,
            "line2" : line2,
            "postal_code" : postal_code,
            "state" : state
        ])
    }
}
