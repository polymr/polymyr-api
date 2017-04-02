//
//  Campaign.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import FluentProvider
import Foundation
import Node

final class Campaign: Model, Preparation, JSONConvertible, NodeConvertible, Sanitizable {
    
    static var permitted: [String] = ["units", "purchasedUnits", "endDate", "amountOff", "product_id", "maker_id"]

    let storage = Storage()
    
    var id: Identifier?
    var exists = false
    
    let units: Int
    let purchasedUnits: Int
    
    let endDate: Date
    let amountOff: Double
    
    var product_id: Identifier
    var maker_id: Identifier
    
    init(node: Node) throws {
        id = try node.get("id")
        units = try node.get("units")
        purchasedUnits = (try? node.get("purchasedUnits")) ?? 0
        
        endDate = try node.get("endDate")
        amountOff = try node.get("amountOff")
        
        product_id = try node.get("product_id")
        maker_id = try node.get("maker_id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
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
        try database.create(Campaign.self) { campaign in
            campaign.id(for: Campaign.self)
            campaign.int("units")
            campaign.int("purchasedUnits")
            campaign.string("endDate")
            campaign.double("amountOff")
            campaign.parent(idKey: "product_id", idType: .int)
            campaign.parent(idKey: "maker_id", idType: .int)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Campaign.self)
    }
}

extension Campaign {

    func maker() -> Parent<Campaign, Maker> {
        return parent(id: "maker_id")
    }

    func product() -> Parent<Campaign, Product> {
        return parent(id: "product_id")
    }
}
