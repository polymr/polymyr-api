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

fileprivate let separator = "@@@<<<>>>@@@"

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
        qualifiers = try? node.parseList(at: "qualifiers", with: separator)
        
        campaign_id = try node.extract("campaign_id")
        section_id = try node.extract("section_id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: []).add(objects: [
            "campaign_id" : campaign_id,
            "section_id" : section_id,
            "id" : id,
            "text" : text,
            "qualifiers" : qualifiers?.serialize(with: context)
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Question.self) { question in
            question.id(for: Question.self)
            question.string("text")
            question.parent(idKey: "campaign_id", idType: .int)
            question.parent(idKey: "section_id", idType: .int)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Question.self)
    }
}
