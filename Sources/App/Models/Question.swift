//
//  Question.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import Sanitized

fileprivate let separator = "@@@<<<>>>@@@"

final class Question: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted: [String] = ["text", "qualifiers", "campaign_id", "section_id"]
    
    var id: Node?
    var exists = false
    
    // One will be provided
    let text: String?
    let qualifiers: [String]?
    
    let campaign_id: Node?
    let section_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        text = try node.extract("text")
        qualifiers = try? node.parseList(at: "qualifiers", with: separator)
        
        campaign_id = node["campaign_id"]
        section_id = node["section_id"]
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "campaign_id" : campaign_id!,
            "section_id" : section_id!
        ]).add(objects: [
            "id" : id,
            "text" : text,
            "qualifiers" : qualifiers?.serialize(with: context)
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { question in
            question.id()
            question.string("text")
            question.parent(Campaign.self)
            question.parent(idKey: "section_id")
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}
