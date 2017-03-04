//
//  Address.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import Sanitized

final class CustomerAddress: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted: [String] = ["customer_id", "address", "firstName", "lastName", "apartment", "city", "state", "zip", "isDefault", "phoneNumber"]
    
    var id: Node?
    var exists = false
    
    let firstName: String
    let lastName: String
    
    let address: String
    let apartment: String?
    
    let city: String
    let state: String
    let zip: String
    let phoneNumber: String?
    
    var customer_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = node["id"]
        
        customer_id = try node.extract("customer_id")
        address = try node.extract("address")
        firstName = try node.extract("firstName")
        lastName = try node.extract("lastName")
        city = try node.extract("city")
        state = try node.extract("state")
        zip = try node.extract("zip")
        phoneNumber = try node.extract("phoneNumber")
        apartment = try node.extract("apartment")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "address" : .string(address),
            "city" : .string(city),
            "state" : .string(state),
            "zip" : .string(zip),
            "customer_id" : customer_id!,
            "firstName" : .string(firstName),
            "lastName" : .string(lastName),
        ]).add(objects: [
            "id" : id,
            "apartment" : apartment,
            "phoneNumber" : phoneNumber
        ])
    }
    
    func postValidate() throws {
        guard (try? customer().first()) ?? nil != nil else {
            throw ModelError.missingLink(from: CustomerAddress.self, to: Customer.self, id: customer_id?.int)
        }
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { shipping in
            shipping.id()
            shipping.string("address")
            shipping.string("apartment", optional: true)
            shipping.string("city")
            shipping.string("state")
            shipping.string("zip")
            shipping.string("firstName")
            shipping.string("lastName")
            shipping.string("phoneNumber")
            shipping.bool("isDefault")
            shipping.parent(Customer.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension CustomerAddress {
    
    func customer() throws -> Parent<Customer> {
        return try parent(customer_id)
    }
}
