//
//  Entity+Relation.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/28/16.
//
//

import Fluent
import Vapor

extension Array where Element : NodeRepresentable {
    
    public func makeJSON() throws -> JSON {
        let node = try Node.array(self.map { try $0.makeNode() })
        return try JSON(node: node)
    }
}

extension Array where Element : NodeInitializable {
    
    public init(json: JSON) throws {
        let node = json.makeNode()
        try self.init(node: node)
    }
}
