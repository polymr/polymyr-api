//
//  VendorAddress.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import FluentProvider
import Node

final class MakerAddress: Model, Preparation, JSONConvertible, NodeConvertible, Sanitizable {

    let storage = Storage()
    
    static var permitted: [String] = ["address", "apartment", "city", "state", "zip"]
    
    var id: Identifier?
    var exists = false
    
    let address: String
    let apartment: String?
    
    let city: String
    let state: String
    let zip: String
    
    init(node: Node) throws {
        id = try node.get("id")
        
        address = try node.get("address")
        city = try node.get("city")
        state = try node.get("state")
        zip = try node.get("zip")
        
        apartment = try node.get("apartment")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "address" : .string(address),
            "city" : .string(city),
            "state" : .string(state),
            "zip" : .string(zip)
        ]).add(objects: [
            "id" : id,
            "apartment" : apartment
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(MakerAddress.self) { shipping in
            shipping.id(for: MakerAddress.self)
            shipping.string("address")
            shipping.string("apartment", optional: true)
            shipping.string("city")
            shipping.string("state")
            shipping.string("zip")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(MakerAddress.self)
    }
}
