//
//  QuestionSection.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import FluentProvider
import Node

final class QuestionSection: Model, Preparation, NodeConvertible, Sanitizable {

    let storage = Storage()
    
    static var permitted: [String] = ["name", "description", "suggestions", "isRating"]
    
    var id: Identifier?
    var exists = false
    
    let name: String
    let description: String
    let suggestions: [String]
    let isRating: Bool
    
    init(node: Node) throws {
        id = try? node.extract("id")
        name = try node.extract("name")
        suggestions = try node.extract("suggestions")
        description = try node.extract("description")
        isRating = try node.extract("isRating")
    }
    
    convenience init(row: Row) throws {
        var node = row.makeNode(in: rowContext)

        let bytes: String = try row.extract("bytes")
        let parsed = try JSON(bytes: bytes.makeBytes())
        node["suggestions"] = parsed.converted(to: Node.self)
        
        try self.init(node: node)
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "name" : .string(name),
            "description" : .string(description),
            "suggestions" : serialize(suggestions, in: context) as Node,
            "isRating" : .bool(isRating)
        ]).add(objects: [
            "id" : id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(QuestionSection.self) { questionSection in
            questionSection.id()
            questionSection.string("name")
            questionSection.string("description")
            questionSection.string("suggestions")
            questionSection.bool("isRating")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(QuestionSection.self)
    }
}
