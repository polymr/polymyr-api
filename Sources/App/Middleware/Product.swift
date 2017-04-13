//
//  Product.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import FluentProvider

final class Product: Model, Preparation, JSONConvertible, NodeConvertible, Sanitizable {

    let storage = Storage()
    
    static var permitted: [String] = ["name", "fullPrice", "shortDescription", "longDescription", "maker_id", "created"]
    
    var id: Identifier?
    var exists = false
    
    let name: String
    let fullPrice: Double
    let shortDescription: String
    let longDescription: String
    let created: Date
    
    let maker_id: Identifier
    
    init(node: Node) throws {
        id = try? node.extract("id")
        
        name = try node.extract("name")
        fullPrice = try node.extract("fullPrice")
        shortDescription = try node.extract("shortDescription")
        longDescription = try node.extract("longDescription")
        created = (try? node.extract("created")) ?? Date()
        
        maker_id = try node.extract("maker_id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "name" : .string(name),
            "fullPrice" : .number(.double(fullPrice)),
            "shortDescription" : .string(shortDescription),
            "longDescription" : .string(longDescription),
            "created" : .date(created)
        ]).add(objects: [
            "id" : id,
            "maker_id" : maker_id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Product.self) { product in
            product.id()
            product.string("name")
            product.double("fullPrice")
            product.string("shortDescription")
            product.string("longDescription")
            product.string("created")
            product.parent(idKey: "maker_id", idType: .int)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Product.self)
    }
}

extension Product {
    
    func maker() -> Parent<Product, Maker> {
        return parent(id: maker_id)
    }
    
    func campaign() -> Children<Product, Campaign> {
        return children()
    }
    
    func tags() -> Siblings<Product, Tag, Pivot<Product, Tag>> {
        return siblings()
    }
    
    func pictures() -> Children<Product, ProductPicture> {
        return children()
    }
}
