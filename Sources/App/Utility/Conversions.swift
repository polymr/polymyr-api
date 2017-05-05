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
import HTTP

extension Model where Self: NodeConvertible {

    public init(row: Row) throws {
        try self.init(node: Node(row.wrapped, in: nil))
    }

    public func makeRow() throws -> Row {
        return try Row(self.makeNode(in: rowContext).wrapped, in: rowContext)
    }
}

extension NodeRepresentable {

    func makeResponse() throws -> Response {
        let json: JSON = try makeNode(in: jsonContext).converted()
        return try Response(status: .ok, json: json)
    }
}

func serialize<R: StructuredDataWrapper>(_ _array: [Int]?, in _context: Context?) throws -> R {
    guard let array = _array else {
        return R(.array([]), in: emptyContext)
    }

    if let context = _context, context.isRow {
        let serialized = try JSON(node: array).serialize().makeString()
        return R(.string(serialized), in: emptyContext)
    } else {
        return try R(Node(node: array, in: emptyContext).wrapped, in: emptyContext)
    }
}

func serialize<R: StructuredDataWrapper>(_ _array: [String]?, in _context: Context?) throws -> R {
    guard let array = _array else {
        return R(.array([]), in: emptyContext)
    }

    if let context = _context, context.isRow {
        let serialized = try JSON(node: array).serialize().makeString()
        return R(.string(serialized), in: emptyContext)
    } else {
        return try R(Node(node: array, in: emptyContext).wrapped, in: emptyContext)
    }
}
