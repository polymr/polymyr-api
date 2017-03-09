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
    
    static var permitted: [String] = ["campaign_id", "product_id", "maker_id", "customer_id"]
    
    var id: Node?
    var exists = false
    
    let campaign_id: Node?
    let product_id: Node?
    let maker_id: Node?
    let customer_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = node["id"]
        
        campaign_id = node["campaign_id"]
        product_id = node["product_id"]
        maker_id = node["maker_id"]
        customer_id = node["customer_id"]
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: []).add(objects: [
            "id" : id,
            "campaign_id" : campaign_id,
            "product_id" : product_id,
            "maker_id" : maker_id,
            "customer_id" : customer_id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { order in
            order.id()
            order.parent(Campaign.self)
            order.parent(Product.self)
            order.parent(Maker.self)
            order.parent(Customer.self)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

