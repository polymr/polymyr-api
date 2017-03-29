//
//  Answer.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import Sanitized

fileprivate let separator = "@"

final class Answer: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted: [String] = ["text", "ratings", "question_id", "order_id", "campaign_id"]
    
    var id: Node?
    var exists = false
    
    // One will be filled out
    let text: String?
    let ratings: [Int]?
    
    var question_id: Node?
    var order_id: Node?
    var campaign_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = node["id"]
        text = try node.extract("text")
        ratings = (try? node.parseList(at: "ratings", with: separator).map { $0.int }.flatMap { $0 })
        
        question_id = node["question_id"]
        order_id = node["order_id"]
        campaign_id = node["campaign_id"]
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: []).add(objects: [
            "id" : id,
            "ratings" : ratings?.map { String(describing: $0) }.joined(separator: separator),
            "text" : text,
            "question_id" : question_id,
            "order_id" : order_id,
            "campaign_id" : campaign_id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { answer in
            answer.id()
            answer.string("text")
            answer.parent(Question.self)
            answer.parent(Order.self)
            answer.parent(Campaign.self)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}
