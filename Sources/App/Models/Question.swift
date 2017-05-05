//
//  Question.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import FluentProvider
import Node

final class Question: Model, Preparation, NodeConvertible, Sanitizable {

    let storage = Storage()
    
    static var permitted: [String] = ["text", "qualifiers", "campaign_id", "question_section_id"]
    
    var id: Identifier?
    var exists = false
    
    // One will be provided
    let text: String?
    let qualifiers: [String]?
    
    let campaign_id: Identifier
    let question_section_id: Identifier
    
    init(node: Node) throws {
        id = try? node.extract("id")
        text = try? node.extract("text")
        qualifiers = try? node.extract("qualifiers")
        
        campaign_id = try node.extract("campaign_id")
        question_section_id = try node.extract("question_section_id")
    }
    
    convenience init(row: Row) throws {
        var node = row.makeNode(in: rowContext)

        let bytes: String = try row.extract("qualifiers")
        let parsed = try JSON(bytes: bytes.makeBytes())
        node["qualifiers"] = parsed.converted(to: Node.self)
        
        try self.init(node: node)
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node.object([:]).add(objects: [
            "campaign_id" : campaign_id,
            "question_section_id" : question_section_id,
            "id" : id,
            "text" : text,
            "qualifiers" : serialize(qualifiers, in: context) as Node
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Question.self) { question in
            question.id()
            question.string("text")
            question.string("qualifiers")
            question.parent(Campaign.self)
            question.parent(QuestionSection.self)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Question.self)
    }
}
