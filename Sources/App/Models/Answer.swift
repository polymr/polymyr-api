//
//  Answer.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import FluentProvider
import Node

final class Answer: Model, Preparation, JSONConvertible, NodeConvertible, Sanitizable {

    let storage = Storage()
    
    static var permitted: [String] = ["text", "ratings", "question_id", "order_id", "campaign_id"]
    
    var id: Identifier?
    var exists = false
    
    // One will be filled out
    let text: String?
    let ratings: [Int]?
    
    var question_id: Identifier
    var order_id: Identifier
    var campaign_id: Identifier
    
    init(node: Node) throws {
        id = try? node.extract("id")
        text = try? node.extract("text")
        ratings = try? node.extract("ratings")
        
        question_id = try node.extract("question_id")
        order_id = try node.extract("order_id")
        campaign_id = try node.extract("campaign_id")
    }
    
    convenience init(row: Row) throws {
        var node = row.makeNode(in: rowContext)
        
        let parsed = try JSON(serialized: row.extract("ratings") as String)
        node["ratings"] = parsed.converted(to: Node.self)
        
        try self.init(node: node)
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node.object([:]).add(objects: [
            "id" : id,
            "ratings" : serialize(ratings, in: context) as Node,
            "text" : text,
            "question_id" : question_id,
            "order_id" : order_id,
            "campaign_id" : campaign_id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Answer.self) { answer in
            answer.id()
            answer.string("text", optional: true)
            answer.string("ratings", optional: true)
            answer.parent(Question.self)
            answer.parent(Order.self)
            answer.parent(Campaign.self)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Answer.self)
    }
}
