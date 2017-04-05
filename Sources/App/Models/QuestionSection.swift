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

fileprivate let separator = "@@@<<<>>>@@@"

extension Sequence where Iterator.Element == String {
    
    func serialize(with _context: Context?, with separator: String = "@@@<<<>>>@@@") -> Node {
        if let context = _context, context.isMySQL {
            return .string(self.joined(separator: separator))
        }
        
        return .array(self.map { Node.string($0) })
    }
}

final class QuestionSection: Model, Preparation, JSONConvertible, NodeConvertible, Sanitizable {

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
        suggestions = try node.parseList(at: "suggestions", with: separator)
        description = try node.extract("description")
        isRating = try node.extract("isRating")
    }
    
    func makeNode(in context: Context?) throws -> Node {
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
        try database.create(QuestionSection.self) { questionSection in
            questionSection.id(for: Question.self)
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
