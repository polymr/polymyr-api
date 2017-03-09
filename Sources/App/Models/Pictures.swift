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

    required init(node: Node, in context: Context = EmptyNode) throws {
        id = node["id"]
        url = try node.extract("url")
        owner_id = node["owner_id"]
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "url" : .string(url)
            ]).add(objects: [
                "id" : id,
                "owner_id" : owner_id
                ])
    }
    
    static func prepare(_ database: Database) throws {
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
final class ProductPicture: Picture {}
final class CustomerPicture: Picture {}
