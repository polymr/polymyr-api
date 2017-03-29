//
//  Node+Convenience.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Foundation
import Node
import JSON
import Fluent
import Vapor

struct OwnerContext: Context {

    var owner_id: Node

    init?(from entity: Entity) {
        guard let id = entity.id else {
            return nil
        }

        owner_id = id
    }

    init(with id: Int) {
        owner_id = .number(.int(id))
    }
}

extension Node: JSONConvertible {
    
    mutating func substitute(key: String, model: Model) throws -> Node {
        precondition(!key.hasSuffix("_id"))
        
        self["\(key)_id"] = nil
        self[key] = try model.makeNode()
        
        return self
    }
    
    mutating func merge(with json: JSON) throws -> Node {
        guard let update = json.node.nodeObject else {
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
        guard var object = self.nodeObject else { throw NodeError.unableToConvert(node: self, expected: "[String: Node].self") }
        object[name] = node
        return try Node(node: object)
    }
    
    func add(objects: [String : NodeConvertible?]) throws -> Node {
        guard var nodeObject = self.nodeObject else { throw NodeError.unableToConvert(node: self, expected: "[String: Node].self") }
        
        for (name, object) in objects {
            if let node = try object?.makeNode() {
                nodeObject[name] = node
            }
        }
        
        return try Node(node: nodeObject)
    }
}

public extension RawRepresentable where Self: NodeConvertible, RawValue == String {
    
    public init(node: Node, in context: Context = EmptyNode) throws {
        
        guard let string = node.string else {
            throw NodeError.unableToConvert(node: node, expected: "\(String.self)")
        }
        
        guard let value = Self.init(rawValue: string) else {
            throw NodeError.unableToConvert(node: nil, expected: "todo")
        }
        
        self = value
    }
    
    public func makeNode(context: Context = EmptyNode) throws -> Node {
        return Node.string(self.rawValue)
    }
    
    public init?(from string: String) throws {
        guard let value = Self.init(rawValue: string) else {
            throw Abort.custom(status: .badRequest, message: "\(string) is not a valid value for for \(Self.self)")
        }
        
        self = value
    }
}

public extension Date {
    
    public init(ISO8601String: String) throws {
        let dateFormatter = DateFormatter()
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        guard let date = dateFormatter.date(from: ISO8601String) else {
            throw Abort.custom(status: .internalServerError, message: "Error parsing date string : \(ISO8601String)")
        }
        
        self = date
    }
    
    public var ISO8601String: String {
        let dateFormatter = DateFormatter()
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        return dateFormatter.string(from: self)
    }
}


extension Model {
    
    mutating func update(from json: JSON) throws -> Self {
        var node = try self.makeNode()
        var result = try Self.init(node: node.merge(with: json), in: EmptyNode)
        result.exists = self.exists
        return result
    }
}

extension Date: NodeConvertible {
    
    public func makeNode(context: Context = EmptyNode) throws -> Node {
        return .string(self.ISO8601String)
    }
    
    public init(node: Node, in context: Context) throws {
        
        if case let .number(numberNode) = node {
            self = Date(timeIntervalSince1970: numberNode.double)
        } else if case let .string(value) = node {
            self = try Date(ISO8601String: value)
        } else {
            throw NodeError.unableToConvert(node: node, expected: "UNIX timestamp or ISO string.")
        }
    }
}


public extension Node {
    
    // TODO : rename to extract stripe list
    func extractList<T: NodeInitializable>(_ path: PathIndex...) throws -> [T] {
        guard let node = self[path] else {
            throw NodeError.unableToConvert(node: self, expected: "path at \(path)")
        }
        
        guard node["object"]?.string == "list" else {
            throw NodeError.unableToConvert(node: node, expected: "object key with list value")
        }
        
        guard let data = node["data"] else {
            throw NodeError.unableToConvert(node: node, expected: "data key with list values")
        }
        
        return try [T](node: data)
    }
    
    func parseList(at key: String, with separator: String) throws -> [String] {
        guard let object = self[key] else {
            throw Abort.custom(status: .badRequest, message: "Missing list or string at \(key)")
        }
        
        switch object {
        case let .array(strings):
            return strings.map { $0.string }.flatMap { $0 }
        case let .string(string):
            return string.components(separatedBy: separator)
        default:
            throw Abort.custom(status: .badRequest, message: "Unknown format for \(key)... got \(object.type)")
        }
    }
}

extension Node {
    
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
        }
    }
    
}
