//
//  Campaign.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Foundation
import Vapor
import Fluent
import Sanitized

final class Campaign: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted: [String] = ["units", "purchasedUnits", "endDate", "amountOff", "product_id", "maker_id"]
    
    var id: Node?
    var exists = false
    
    let units: Int
    let purchasedUnits: Int
    
    let endDate: Date
    let amountOff: Double
    
    var product_id: Node?
    var maker_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = node["id"]
        units = try node.extract("units")
        purchasedUnits = (try? node.extract("purchasedUnits")) ?? 0
        
        endDate = try node.extract("endDate")
        amountOff = try node.extract("amountOff")
        
        product_id = node["product_id"]
        maker_id = node["maker_id"]
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "units" : .number(.int(units)),
            "purchasedUnits" : .number(.int(purchasedUnits)),
            "endDate" : .string(endDate.ISO8601String),
            "amountOff" : .number(.double(amountOff))
        ]).add(objects: [
            "id" : id,
            "product_id" : product_id,
            "maker_id" : maker_id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { campaign in
            campaign.id()
            campaign.int("units")
            campaign.int("purchasedUnits")
            campaign.string("endDate")
            campaign.double("amountOff")
            campaign.parent(Product.self)
            campaign.parent(Maker.self)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Campaign {

    func maker() throws -> Parent<Maker> {
        return try parent(maker_id)
    }

    func product() throws -> Parent<Product> {
        return try parent(product_id)
    }
}
