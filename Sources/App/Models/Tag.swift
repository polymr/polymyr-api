//
//  Tag.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/4/17.
//
//

import Foundation
import Vapor
import Fluent
import Sanitized

final class Tag: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted: [String] = ["name"]
    
    var id: Node?
    var exists = false
    
    let name: String
    
    init(node: Node, in context: Context) throws {
        id = node["id"]
        name = try node.extract("name")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: []).add(objects: [
            "id" : id,
            "name" : name
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { answer in
            answer.id()
            answer.string("name")
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Tag {
    
    func products() throws -> Siblings<Product> {
        return try siblings()
    }
}
