//
//  Session.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import Auth

enum SessionType: String, TypesafeOptionsParameter {
    case customer
    case maker
    case none
    
    static let key = "type"
    static let values = [SessionType.customer.rawValue, SessionType.maker.rawValue, SessionType.none.rawValue]
    
    static var defaultValue: SessionType? = .none
}

extension AccessToken: NodeRepresentable {
    
    public func makeNode(context: Context = EmptyNode) throws -> Node {
        return .string(self.string)
    }
}

final class Session: Model, Preparation, JSONConvertible {
    
    var id: Node?
    var exists = false
    
    let accessToken: String
    let type: SessionType
    
    var customer_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        accessToken = try node.extract("accessToken")
        customer_id = try node.extract("customer_id")
        
        type = try node.extract("type") { (_type: String) in
            return SessionType(rawValue: _type)
        }!
    }
    
    init(id: String? = nil, token: String, subject_id: String, type: SessionType) {
        self.id = id.flatMap { .string($0) }
        self.accessToken = token
        self.customer_id = .string(subject_id)
        self.type = type
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "accessToken" : .string(accessToken),
            "customer_id" : customer_id!,
            "type" : .string(type.rawValue)
            ]).add(name: "id", node: id)
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { session in
            session.id()
            session.string("accessToken")
            session.string("type")
            session.parent(Customer.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Session {
    
    func user() throws -> Parent<Customer> {
        precondition(self.type == .customer)
        return try parent(customer_id)
    }
    
    func maker() throws -> Parent<Maker> {
        precondition(self.type == .maker)
        return try parent(customer_id)
    }
    
    static func session(forToken token: AccessToken, type: SessionType) throws -> Session {
        let query = try Session.query().filter("accessToken", token).filter("type", type)
        
        guard let session = try query.first() else {
            throw AuthError.invalidCredentials
        }
        
        return session
    }
}
