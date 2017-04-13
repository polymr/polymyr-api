//
//  Node+Convenience.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Node
import JSON
import Fluent
import FluentProvider
import Vapor
import Foundation

extension NodeError {
    func appendPath(_ path: [PathIndexer]) -> NodeError {
        switch self {
        case .unableToConvert(
            input: let input,
            expectation: let expectation,
            path: let existing
            ) where existing.isEmpty:
            return .unableToConvert(input: input, expectation: expectation, path: path)
        default:
            return self
        }
    }
}

extension StructuredDataWrapper {
    
    public func extract<T : NodeInitializable>(_ indexers: PathIndexer...) throws -> T {
        return try extract(indexers)
    }

    public func extract<T : NodeInitializable>(_ indexers: [PathIndexer]) throws -> T {
        if let value = self[indexers], value != .null {
            return try T(node: value)
        }

        throw try NodeError.unableToConvert(input: self.makeNode(in: nil), expectation: "\(T.self)", path: indexers)
    }

    public func extract<T, InputType: NodeInitializable>(_ indexers: PathIndexer..., transform: (InputType) throws -> T) throws -> T {
        return try get(path: indexers, transform: transform)
    }

    public func extract<T, InputType: NodeInitializable>(path indexers: [PathIndexer], transform: (InputType) throws -> T) throws -> T {
        if let value = self[indexers], value != .null {
            let input = try InputType(node: value, in: context)
            return try transform(input)
        }

        throw try NodeError.unableToConvert(input: self.makeNode(in: nil), expectation: "\(Node.self)", path: indexers)
    }
}


extension Node {
    
    mutating func merge(with json: JSON) throws -> Node {
        guard let update = json.node.object else {
            throw Abort.custom(status: .badRequest, message: "Expected [String : Object] node but got \(json.node)")
        }
        
        for (key, object) in update {
            self[key] = object
        }
        
        return self
    }
    
    func add(name: String, node: Node?) throws -> Node {
        if let node = node {
            return try add(name: name, node: node)
        }
        
        return self
    }
    
    func add(name: String, node: Node) throws -> Node {
        guard var object = self.object else { throw NodeError.unableToConvert(input: self, expectation: "[String: Node].self", path: [name]) }
        object[name] = node
        return try Node(node: object)
    }
    
    func add(objects: [String : NodeConvertible?]) throws -> Node {
        guard var previous = self.object else {
            throw NodeError.invalidContainer(container: "object", element: "self")
        }
        
        for (name, object) in objects {
            previous[name] = try object.makeNode(in: emptyContext)
        }
        
        return try Node(node: previous)
    }
}

public extension RawRepresentable where Self: NodeConvertible, RawValue == String {
    
    public init(node: Node) throws {
        
        guard let string = node.string else {
            throw NodeError.unableToConvert(input: node, expectation: "\(String.self)", path: ["self"])
        }
        
        guard let value = Self.init(rawValue: string) else {
            throw Abort.custom(status: .badRequest, message: "Invalid node for \(Self.self)")
        }
        
        self = value
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return Node.string(self.rawValue)
    }
    
    public init?(from string: String) throws {
        guard let value = Self.init(rawValue: string) else {
            throw Abort.custom(status: .badRequest, message: "\(string) is not a valid value for for \(Self.self)")
        }
        
        self = value
    }
}

public extension Node {
    
    // TODO : rename to extract stripe list
    func extractList<T: NodeInitializable>(_ path: PathIndexer...) throws -> [T] {
        guard let node = self[path] else {
            throw NodeError.unableToConvert(input: self, expectation: "stripe list", path: path)
        }
        
        guard try node.extract("object") as String == "list" else {
            throw NodeError.unableToConvert(input: node, expectation: "list", path: ["object"])
        }
        
        guard let data = node["data"]?.array else {
            throw NodeError.unableToConvert(input: node, expectation: "\(Array<Node>.self)", path: ["object"])
        }
        
        return try [T](node: data)
    }
    
    func parseList(at key: String, with separator: String) throws -> [String] {
        guard let object = self[key] else {
            throw Abort.custom(status: .badRequest, message: "Missing list or string at \(key)")
        }
        
        switch object.wrapped {
        case let .array(strings):
            return strings.map { $0.string }.flatMap { $0 }
        case let .string(string):
            return string.components(separatedBy: separator)
        default:
            throw Abort.custom(status: .badRequest, message: "Unknown format for \(key)... got \(object.wrapped.type)")
        }
    }
}

extension StructuredData {
    
    var type: String {
        switch self {
        case .array(_):
            return "array"
        case .null:
            return "null"
        case .bool(_):
            return "bool"
        case .bytes(_):
            return "bytes"
        case let .number(number):
            switch number {
            case .int(_):
                return "number.int"
            case .double(_):
                return "number.double"
            case .uint(_):
                return "number.uint"
            }
        case .object(_):
            return "object"
        case .string(_):
            return "string"
        case .date(_):
            return "date"
        }
    }
    
}
