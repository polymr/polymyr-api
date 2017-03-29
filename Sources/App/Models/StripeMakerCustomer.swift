//
//  StripeMakerCustomer.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent

final class StripeMakerCustomer: Model, Preparation {
    
    var id: Node?
    var exists: Bool = false
    
    let customer_id: Node
    let maker_id: Node
    let stripeCustomerId: String
    
    init(maker: Maker, customer: Customer, account: String) throws {
        guard let maker_id = maker.id else {
            throw Abort.custom(status: .internalServerError, message: "Missing maker id for StripeMakerCustomer link.")
        }
        
        guard let customer_id = customer.id else {
            throw Abort.custom(status: .internalServerError, message: "Missing customer id for StripeMakerCustomer link.")
        }
        
        self.customer_id = customer_id
        self.maker_id = maker_id
        self.stripeCustomerId = account
    }
    
    init(node: Node, in context: Context) throws {
        id = node["id"]
        
        customer_id = try node.extract("customer_id")
        maker_id = try node.extract("maker_id")
        stripeCustomerId = try node.extract("stripeCustomerId")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "stripeCustomerId" : stripeCustomerId,
            "customer_id" : customer_id.makeNode(),
            "maker_id" : maker_id.makeNode()
        ]).add(objects: [
            "id" : id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity) { stripeMakerCustomer in
            stripeMakerCustomer.id()
            stripeMakerCustomer.parent(Customer.self)
            stripeMakerCustomer.parent(Maker.self)
            stripeMakerCustomer.string("stripeCustomerId")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension StripeMakerCustomer {
    
    func vendor() throws -> Parent<Maker> {
        return try parent(maker_id)
    }
    
    func customer() throws -> Parent<Customer> {
        return try parent(customer_id)
    }
}
