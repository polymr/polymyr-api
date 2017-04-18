//
//  Order.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/4/17.
//
//

import Vapor
import Fluent
import FluentProvider
import Node

fileprivate let separator = "@@@<<<>>>@@@"

final class Order: Model, Preparation, JSONConvertible, NodeConvertible, Sanitizable {

    let storage = Storage()
    
    static var permitted: [String] = ["campaign_id", "product_id", "maker_id", "customer_id", "customer_address_id", "card"]
    
    var id: Identifier?
    var exists = false
    
    let product_id: Identifier
    var campaign_id: Identifier
    var maker_id: Identifier
    
    let customer_id: Identifier
    let customer_address_id: Identifier
    
    var charge_id: String?
    let card: String

    let fulfilled: Bool
    
    init(node: Node) throws {
        id = try? node.extract("id")
        
        card = try node.extract("card")
        charge_id = try? node.extract("charge_id")
        
        product_id = try node.extract("product_id")
        customer_address_id = try node.extract("customer_address_id")
        customer_id = try node.extract("customer_id")

        fulfilled = (try? node.extract("fulfilled")) ?? false

        guard let product = try Product.find(product_id) else {
            throw NodeError.unableToConvert(input: product_id.makeNode(in: emptyContext), expectation: "product_id pointing to correct product", path: ["product_id"])
        }
        
        guard let campaign_id = try product.campaign().first()?.id else {
            throw try Abort.custom(status: .badGateway, message: "missing campaign id in linked product \(product.throwableId())")
        }

        self.campaign_id = campaign_id
        maker_id = product.maker_id
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "card" : card
        ]).add(objects: [
            "id" : id,
            "campaign_id" : campaign_id,
            "product_id" : product_id,
            "maker_id" : maker_id,
            "customer_id" : customer_id,
            "customer_address_id" : customer_address_id,
            "charge_id" : charge_id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Order.self) { order in
            order.id()
            order.string("card")
            order.string("charge_id")
            order.bool("fulfilled", default: false)
            order.parent(Campaign.self)
            order.parent(Product.self)
            order.parent(Maker.self)
            order.parent(Customer.self)
            order.parent(CustomerAddress.self)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Order.self)
    }
}

extension Order {
    
    func maker() -> Parent<Order, Maker> {
        return parent(id: maker_id)
    }
    
    func campaign() -> Parent<Order, Campaign> {
        return parent(id: campaign_id)
    }
    
    func product() -> Parent<Order, Product> {
        return parent(id: product_id)
    }
    
    func customer() -> Parent<Order, Customer> {
        return parent(id: customer_id)
    }
}

