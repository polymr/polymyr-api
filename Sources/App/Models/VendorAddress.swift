//
//  VendorAddress.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import Sanitized

final class MakerAddress: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted: [String] = ["address", "apartment", "city", "state", "zip"]
    
    var id: Node?
    var exists = false
    
    let address: String
    let apartment: String?
    
    let city: String
    let state: String
    let zip: String
    
    init(node: Node, in context: Context) throws {
        id = try? node.extract("id")
        
        address = try node.extract("address")
        city = try node.extract("city")
        state = try node.extract("state")
        zip = try node.extract("zip")
        
        apartment = try node.extract("apartment")
    }
    
    func makeNode(context: Context) throws -> Node {
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
        try database.create(self.entity, closure: { shipping in
            shipping.id()
            shipping.string("address")
            shipping.string("apartment", optional: true)
            shipping.string("city")
            shipping.string("state")
            shipping.string("zip")
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}
