//
//  File.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/18/17.
//
//

import Node
import Vapor
import Foundation

fileprivate func parseEvent(from string: String) throws -> (EventResource, EventAction) {
    let components = string.components(separatedBy: ".")
    
    let _resource = components[0..<components.count - 1].joined(separator: ".").lowercased()
    let _action = components[components.count - 1].lowercased()
    
    guard let resource = EventResource(rawValue: _resource), let action = EventAction(rawValue: _action) else {
        throw Abort.custom(status: .internalServerError, message: "Unsupported event type.")
    }
    
    return (resource, action)
}

public enum EventAction: String {
    
    case updated
    case deleted
    case created
    case pending
    case failed
    case refunded
    case succeeded
}

public enum EventResource: String {
    
    case account
    case charge
    case invoice
    
    var internalModelType: NodeConvertible.Type {
        switch self {
        case .account:
            return StripeAccount.self
        case .charge:
            return Charge.self
        case .invoice:
            return Invoice.self
        }
    }
}

public final class EventData: NodeConvertible {
    
    public let object: NodeConvertible
    public let previous_attributes: Node
    
    public init(node: Node) throws {
        
        guard let dictionaryContext = node.context as? ObjectContext<String, EventResource>, let resource = dictionaryContext.object["resource"] else {
            throw Abort.custom(status: .internalServerError, message: "Missing resource in context.")
        }

        guard let objectNode: Node = try node.extract("object") else {
            throw Abort.custom(status: .internalServerError, message: "Missing object node in event.")
        }
        
        object = try resource.internalModelType.init(node: objectNode)
        previous_attributes = try node.extract("previous_attributes")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "object" : try object.makeNode(in: context),
            "previous_attributes" : previous_attributes
        ])
    }
}

public final class Event: NodeConvertible {
    
    public let id: String
    public let api_version: String
    public let created: Date
    public let data: EventData
    public let livemode: Bool
    public let pending_webhooks: Int
    public let request: String?
    public let type: (EventResource, EventAction)
    
    public var resource: EventResource {
        return type.0
    }
    
    public var action: EventAction {
        return type.1
    }

    public init(node: Node) throws {
        id = try node.extract("id")
        api_version = try node.extract("api_version")
        created = try node.extract("created")
        livemode = try node.extract("livemode")
        pending_webhooks = try node.extract("pending_webhooks")
        request = try node.extract("request")
        
        type = try node.extract("type") { (typeString: String) -> (EventResource, EventAction) in
            return try parseEvent(from: typeString)
        }
        
        guard let dataNode: Node = try node.extract("data") else {
            throw Abort.custom(status: .badRequest, message: "Missing data field on event.")
        }
        
        data = try EventData(node: dataNode, in: ObjectContext<String, EventResource>(["resource" : type.0]))
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "id" : .string(id),
            "api_version" : .string(api_version),
            "created" : try created.makeNode(in: context),
            "data" : try data.makeNode(in: context),
            "livemode" : .bool(livemode),
            "pending_webhooks" : .number(.int(pending_webhooks)),
            "type" : .string("\(resource).\(action)")
        ] as [String : Node]).add(objects: [
            "request" : request
        ])
    }
}
