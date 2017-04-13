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

final class Question: Model, Preparation, JSONConvertible, NodeConvertible, Sanitizable {

    let storage = Storage()
    
    static var permitted: [String] = ["text", "qualifiers", "campaign_id", "section_id"]
    
    var id: Identifier?
    var exists = false
    
    // One will be provided
    let text: String?
    let qualifiers: [String]?
    
    let campaign_id: Identifier
    let section_id: Identifier
    
    init(node: Node) throws {
        id = try? node.extract("id")
        text = try? node.extract("text")
        qualifiers = try? node.extract("qualifiers")
        
        campaign_id = try node.extract("campaign_id")
        section_id = try node.extract("section_id")
    }
    
    convenience init(row: Row) throws {
        var node = row.makeNode(in: rowContext)
        
        let parsed = try JSON(serialized: row.extract("qualifiers") as String)
        node["qualifiers"] = parsed.converted(to: Node.self)
        
        try self.init(node: node)
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node.object([:]).add(objects: [
            "campaign_id" : campaign_id,
            "section_id" : section_id,
            "id" : id,
            "text" : text,
            "qualifiers" : serialize(qualifiers, in: context) as Node
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Question.self) { question in
            question.id(for: Question.self)
            question.string("text")
            question.string("qualifiers")
            question.parent(idKey: "campaign_id", idType: .int)
            question.parent(idKey: "section_id", idType: .int)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Question.self)
    }
}
