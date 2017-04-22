//
//  File.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent
import FluentProvider
import BCrypt
import Node
import AuthProvider
import HTTP

extension Stripe {
    
    func createStandaloneAccount(for customer: Customer, from source: Token, on account: String) throws -> StripeCustomer {
        guard let customerId = customer.id?.int else {
            throw Abort.custom(status: .internalServerError, message: "Missing customer id for customer.")
        }
        
        return try Stripe.shared.createNormalAccount(email: customer.email, source: source.id, local_id: customerId, on: account)
    }
}

final class Customer: Model, Preparation, JSONConvertible, NodeConvertible, Sanitizable, JWTInitializable, SessionPersistable {
    
    static var permitted: [String] = ["email", "name", "default_shipping_id"]

    let storage = Storage()
    
    var id: Identifier?
    var exists = false
    
    let name: String
    let email: String

    var stripe_id: String?
    var sub_id: String?

    init(subject: String, request: Request) throws {
        sub_id = subject

        guard let providerData: Node = try request.json?.extract("providerData") else {
            throw Abort.custom(status: .badRequest, message: "Missing json body...")
        }

        self.name = try providerData.extract("displayName")
        self.email = try providerData.extract("email")
    }
    
    init(node: Node) throws {
        id = try? node.extract("id")
        
        // Name and email are always mandatory
        email = try node.extract("email")
        name = try node.extract("name")
        stripe_id = try? node.extract("stripe_id")
        sub_id = try? node.extract("sub_id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "name" : .string(name),
            "email" : .string(email)
        ]).add(objects: [
            "id" : id,
            "stripe_id" : stripe_id,
            "sub_id" : sub_id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Customer.self) { customer in
            customer.id()
            customer.string("name")
            customer.string("stripe_id", optional: true)
            customer.string("email")
            customer.string("sub_id", optional: true)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Customer.self)
    }
}

extension Customer {
    
    func shippingAddresses() -> Children<Customer, CustomerAddress> {
        return children()
    }
    
    func orders() -> Children<Customer, Order> {
        return children()
    }
}

extension Customer: Authenticatable {}
