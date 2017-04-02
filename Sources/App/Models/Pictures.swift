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

class Picture: Model, JSONConvertible, NodeConvertible, Sanitizable {

    let storage = Storage()

    static var permitted: [String] = ["owner_id", "url", "type"]
    
    var exists: Bool = false
    
    var id: Identifier?
    let owner_id: Identifier
    let url: String
    let index: Int?

    required init(node: Node) throws {
        _ = node.context

        id = try node.get("id")
        url = try node.get("url")

        if let context: ParentContext = node.context as? ParentContext {
            owner_id = context.parent_id
        } else {
            owner_id = try node.get("owner_id")
        }

        index = try node.get("index")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "url" : .string(url)
        ]).add(objects: [
            "id" : id,
            "owner_id" : owner_id,
            "index" : index
        ])
    }
}

final class MakerPicture: Picture, Preparation {

    class func prepare(_ database: Database) throws {
        try database.create(MakerPicture.self) { picture in
            picture.id(for: CustomerPicture.self)
            picture.string("url")
            picture.string("type")
            picture.parent(idKey: "owner_id", idType: .int)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(MakerPicture.self)
    }
}

final class CustomerPicture: Picture, Preparation {

    class func prepare(_ database: Database) throws {
        try database.create(CustomerPicture.self) { picture in
            picture.id(for: CustomerPicture.self)
            picture.string("url")
            picture.string("type")
            picture.parent(idKey: "owner_id", idType: .int)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(CustomerPicture.self)
    }
}

final class ProductPicture: Picture, Preparation {

    let type: Int?
    
    required init(node: Node) throws {
        type = try node.get("type")
            
        try super.init(node: node)
    }
    
    override func makeNode(in context: Context?) throws -> Node {
        return try super.makeNode(in: context).add(objects: ["type" : type])
    }
    
    class func prepare(_ database: Database) throws {
        try database.create(ProductPicture.self) { picture in
            picture.id(for: ProductPicture.self)
            picture.string("url")
            picture.string("type")
            picture.parent(idKey: "owner_id", idType: .int)
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(ProductPicture.self)
    }
}
