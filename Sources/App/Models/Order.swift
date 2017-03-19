//
//  Order.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/4/17.
//
//

import Foundation
import Vapor
import Fluent
import Sanitized

fileprivate let separator = "@@@<<<>>>@@@"

final class Order: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted: [String] = ["campaign_id", "product_id", "maker_id", "customer_id", "customeraddress_id", "card"]
    
    var id: Node?
    var exists = false
    
    let product_id: Node?
    var campaign_id: Node?
    var maker_id: Node?
    
    let customer_id: Node?
    let customeraddress_id: Node?
    
    var charge_id: String?
    let card: String
    
    init(node: Node, in context: Context) throws {
        id = node["id"]
        
        card = try node.extract("card")
        charge_id = try node.extract("charge_id")
        
        product_id = node["product_id"]
        customeraddress_id = node["customeraddress_id"]
        customer_id = node["customer_id"]
        
        campaign_id = node["campaign_id"]
        maker_id = node["maker_id"]
        
        if let product_id = product_id, campaign_id == nil || maker_id == nil {
            guard let product = try Product.find(product_id) else {
                throw NodeError.unableToConvert(node: Node.null, expected: "product_id pointing to correct product")
            }
            
            campaign_id = try product.campaign().first()?.id
            maker_id = product.maker_id
        }
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "card" : card
        ]).add(objects: [
            "id" : id,
            "campaign_id" : campaign_id,
            "product_id" : product_id,
            "maker_id" : maker_id,
            "customer_id" : customer_id,
            "customeraddress_id" : customeraddress_id,
            "charge_id" : charge_id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { order in
            order.id()
            order.string("card")
            order.string("charge_id")
            order.parent(Campaign.self)
            order.parent(Product.self)
            order.parent(Maker.self)
            order.parent(Customer.self)
            order.parent(CustomerAddress.self)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Order {
    
    func maker() throws -> Parent<Maker> {
        return try parent(maker_id)
    }
    
    func campaign() throws -> Parent<Campaign> {
        return try parent(campaign_id)
    }
    
    func product() throws -> Parent<Product> {
        return try parent(product_id)
    }
    
    func customer() throws -> Parent<Customer> {
        return try parent(customer_id)
    }
}

