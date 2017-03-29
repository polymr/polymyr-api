//
//  QuestionSection.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import Sanitized

fileprivate let separator = "@@@<<<>>>@@@"

extension Sequence where Iterator.Element == String {
    
    func serialize(with context: Context, with separator: String = "@@@<<<>>>@@@") -> Node {
        if (context is DatabaseContext) {
            return .string(self.joined(separator: separator))
        }
        
        return .array(self.map { Node.string($0) })
    }
}

final class QuestionSection: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted: [String] = ["name", "description", "suggestions", "isRating"]
    
    var id: Node?
    var exists = false
    
    let name: String
    let description: String
    let suggestions: [String]
    let isRating: Bool
    
    init(node: Node, in context: Context) throws {
        id = node["id"]
        name = try node.extract("name")
        suggestions = try node.parseList(at: "suggestions", with: separator)
        description = try node.extract("description")
        isRating = try node.extract("isRating")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "name" : .string(name),
            "description" : .string(description),
            "suggestions" :  suggestions.serialize(with: context),
            "isRating" : .bool(isRating)
        ]).add(objects: [
            "id" : id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { questionSection in
            questionSection.id()
            questionSection.string("name")
            questionSection.string("description")
            questionSection.string("suggestions")
            questionSection.bool("isRating")
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}
