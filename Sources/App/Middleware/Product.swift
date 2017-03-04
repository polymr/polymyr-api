//
//  Product.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import Foundation
import Sanitized

final class Product: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted: [String] = ["name", "fullPrice", "maker_id"]
    
    var id: Node?
    var exists = false
    
    let name: String
    let fullPrice: Double
    
    let maker_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = node["id"]
        
        name = try node.extract("name")
        fullPrice = try node.extract("fullPrice")
        
        maker_id = node["maker_id"]
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "name" : .string(name),
            "fullPrice" : .number(.double(fullPrice)),
        ]).add(objects: [
            "id" : id!,
            "maker_id" : maker_id!
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity) { product in
            product.id()
            product.string("name")
            product.double("fullPrice")
            product.parent(Maker.self)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Product {
    
    func maker() throws -> Parent<Maker> {
        return try parent(maker_id)
    }
}
