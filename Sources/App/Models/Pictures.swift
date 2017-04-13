//
//  Picture.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/8/17.
//
//

import Vapor
import Fluent
import FluentProvider
import Node

protocol Picture: Model, JSONConvertible, NodeConvertible, Sanitizable, Preparation {

    static func pictures(for owner: Identifier) throws -> Query<Self>
}

final class MakerPicture: Picture {
    
    let storage = Storage()
    
    static var permitted: [String] = ["maker_id", "url"]
    
    var exists: Bool = false
    
    var id: Identifier?
    let maker_id: Identifier
    let url: String
    
    static func pictures(for owner: Identifier) throws -> Query<MakerPicture> {
        return try self.makeQuery().filter("maker_id", owner.int)
    }
    
    init(node: Node) throws {
        _ = node.context
        
        id = try? node.extract("id")
        url = try node.extract("url")
        
        if let context: ParentContext = node.context as? ParentContext {
            maker_id = context.parent_id
        } else {
            maker_id = try node.extract("maker_id")
        }
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "url" : .string(url)
        ]).add(objects: [
            "id" : id,
            "maker_id" : maker_id
        ])
    }

    class func prepare(_ database: Database) throws {
        try database.create(MakerPicture.self) { picture in
            picture.id()
            picture.string("url")
            picture.parent(idKey: "maker_id", idType: .int)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(MakerPicture.self)
    }
}

final class CustomerPicture: Picture {
    
    let storage = Storage()
    
    static var permitted: [String] = ["customer_id", "url"]
    
    var exists: Bool = false
    
    var id: Identifier?
    let customer_id: Identifier
    let url: String
    
    static func pictures(for owner: Identifier) throws -> Query<CustomerPicture> {
        return try self.makeQuery().filter("customer_id", owner.int)
    }
    
    init(node: Node) throws {
        _ = node.context
        
        id = try? node.extract("id")
        url = try node.extract("url")
        
        if let context: ParentContext = node.context as? ParentContext {
            customer_id = context.parent_id
        } else {
            customer_id = try node.extract("customer_id")
        }
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "url" : .string(url)
        ]).add(objects: [
            "id" : id,
            "customer_id" : customer_id
        ])
    }

    class func prepare(_ database: Database) throws {
        try database.create(CustomerPicture.self) { picture in
            picture.id()
            picture.string("url")
            picture.parent(idKey: "customer_id", idType: .int)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(CustomerPicture.self)
    }
}

final class ProductPicture: Picture {
    
    let storage = Storage()
    
    static var permitted: [String] = ["product_id", "url", "type"]
    
    var id: Identifier?
    
    let url: String
    let type: Int?
    let product_id: Identifier
    
    static func pictures(for owner: Identifier) throws -> Query<ProductPicture> {
        return try self.makeQuery().filter("product_id", owner.int)
    }
    
    init(node: Node) throws {
        id = try? node.extract("id")
        url = try node.extract("url")
        type = try? node.extract("type")
        
        if let context: ParentContext = node.context as? ParentContext {
            product_id = context.parent_id
        } else {
            product_id = try node.extract("product_id")
        }
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "url" : .string(url),
        ]).add(objects: [
            "id" : id,
            "product_id" : product_id,
            "type" : type
        ])
    }
    
    class func prepare(_ database: Database) throws {
        try database.create(ProductPicture.self) { picture in
            picture.id()
            picture.string("url")
            picture.int("type")
            picture.parent(idKey: "product_id", idType: .int)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(ProductPicture.self)
    }
}
