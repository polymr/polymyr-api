//
//  Picture.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/8/17.
//
//

import Foundation
import Vapor
import Fluent
import Sanitized

class Picture: Model, Preparation, JSONConvertible, Sanitizable {

    static var permitted: [String] = ["owner_id", "url"]
    
    var exists: Bool = false
    
    var id: Node?
    let owner_id: Node?
    let url: String
    let index: Int?

    required init(node: Node, in context: Context = EmptyNode) throws {
        id = node["id"]
        url = try node.extract("url")
        owner_id = node["owner_id"] ?? (context as? OwnerContext)?.owner_id
        index = try node.extract("index")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "url" : .string(url)
        ]).add(objects: [
            "id" : id,
            "owner_id" : owner_id,
            "index" : index
        ])
    }
    
    class func prepare(_ database: Database) throws {
        try database.create(self.entity) { picture in
            picture.id()
            picture.string("url")
            picture.parent(idKey: "owner_id")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

final class MakerPicture: Picture {}
final class CustomerPicture: Picture {}

final class ProductPicture: Picture {

    let type: Int?
    
    required init(node: Node, in context: Context) throws {
        type = try node.extract("type")
            
        try super.init(node: node, in: context)
    }
    
    override func makeNode(context: Context) throws -> Node {
        return try super.makeNode(context: context).add(objects: ["type" : type])
    }
    
    override class func prepare(_ database: Database) throws {
        try database.create(self.entity) { picture in
            picture.id()
            picture.string("url")
            picture.string("type")
            picture.parent(idKey: "owner_id")
        }
    }
}
