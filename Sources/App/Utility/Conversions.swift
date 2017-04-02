//
//  Entity+Relation.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/28/16.
//
//

import Fluent
import FluentProvider
import Vapor

extension Model where Self: NodeConvertible {

    public init(row: Row) throws {
        try self.init(node: Node(row.wrapped, in: nil))
    }

    public func makeRow() throws -> Row {
        return try Row(self.makeNode(in: rowContext).wrapped, in: rowContext)
    }
}

extension Model where Self: NodeConvertible {

    public init(json: JSON) throws {
        try self.init(node: Node(json.wrapped, in: nil))
    }

    public func makeJSON() throws -> JSON {
        return try JSON(self.makeNode(in: jsonContext).wrapped)
    }
}
