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
        city = try? node.extract("city")
        country = try node.extract("country")
        line1 = try? node.extract("line1")
        line2 = try? node.extract("line2")
        postal_code = try? node.extract("postal_code")
        state = try? node.extract("state")
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
