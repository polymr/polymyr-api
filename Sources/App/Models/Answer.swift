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

fileprivate let separator = "@"

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
        ratings = try? node.parseList(at: "ratings", with: separator).map { $0.int }.flatMap { $0 }
        
        question_id = try node.extract("question_id")
        order_id = try node.extract("order_id")
        campaign_id = try node.extract("campaign_id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
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
        try database.create(Answer.self) { answer in
            answer.id(for: Answer.self)
            answer.string("text")
            answer.parent(idKey: "question_id", idType: .int)
            answer.parent(idKey: "order_id", idType: .int)
            answer.parent(idKey: "campaign_id", idType: .int)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Answer.self)
    }
}
