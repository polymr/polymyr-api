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

    var default_shipping_id: Identifier?
    var stripe_id: String?
    
    var sub_id: String?

    init(subject: String, request: Request) throws {
        sub_id = subject

        guard let providerData: Node = try request.json?.extract("providerData") else {
            throw Abort.custom(status: .badRequest, message: "Missing json body...")
        }

        self.name = try providerData.extract("name")
        self.email = try providerData.extract("email")
    }
    
    init(node: Node) throws {
        id = try? node.extract("id")
        default_shipping_id = try? node.extract("default_shipping_id")
        
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
            "default_shipping_id" : default_shipping_id,
            "sub_id" : sub_id
        ])
    }
    
    func postValidate() throws {
        if default_shipping_id != nil {
            guard (try? defaultShipping().first()) ?? nil != nil else {
                throw ModelError.missingLink(from: Customer.self, to: CustomerAddress.self, id: default_shipping_id?.int ?? -1)
            }
        }
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Customer.self) { customer in
            customer.id(for: Campaign.self)
            customer.string("name")
            customer.string("stripe_id", optional: true)
            customer.string("email")
            customer.string("sub_id", optional: true)
            customer.parent(idKey: "default_shipping_id", idType: .int, optional: true)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Customer.self)
    }
}

extension Customer {

    func defaultShipping() -> Parent<Customer, CustomerAddress> {
        return parent(id: default_shipping_id)
    }
    
    func shippingAddresses() -> Children<Customer, CustomerAddress> {
        return children()
    }
    
    func sessions() -> Children<Customer, CustomerSessionToken> {
        return children(type: CustomerSessionToken.self)
    }
}

final class CustomerSessionToken: Model, Preparation, JSONConvertible, NodeConvertible {

    let storage = Storage()

    var id: Identifier?

    let customer_id: Identifier
    let token: String

    init(node: Node) throws  {
        customer_id = try node.extract("customer_id")
        token = try node.extract("token")
    }

    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "token" : token
        ]).add(objects: [
            "customer_id" : customer_id
        ])
    }

    static func prepare(_ database: Database) throws {
        try database.create(CustomerSessionToken.self) { session in
            session.id(for: CustomerSessionToken.self)
            session.parent(idKey: "customer_id", idType: .int)
            session.string("token")
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(CustomerSessionToken.self)
    }
}

extension Customer: TokenAuthenticatable {

    typealias TokenType = CustomerSessionToken

    public static var tokenKey: String {
        return "token"
    }
}

extension Model {
    
    func throwableId() throws -> Int {
        guard let id = id else {
            throw Abort.custom(status: .internalServerError, message: "Bad internal state. \(type(of: self).entity) does not have database id when it was requested.")
        }
        
        guard let customerIdInt = id.int else {
            throw Abort.custom(status: .internalServerError, message: "Bad internal state. \(type(of: self).entity) has database id but it was of type \(id.wrapped.type) while we expected number.int")
        }
        
        return customerIdInt
    }
}

extension Customer  {

    func orders() -> Children<Customer, Order> {
        return children()
    }
}
