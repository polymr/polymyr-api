//
//  AuthenticationController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import HTTP
import Fluent
import FluentProvider
import Routing
import Node
import JWT
import AuthProvider

enum SessionType: String, TypesafeOptionsParameter {
    case customer
    case maker
    case none

    static let key = "type"
    static let values = [SessionType.customer.rawValue, SessionType.maker.rawValue, SessionType.none.rawValue]

    static var defaultValue: SessionType? = .none
}

final class ProviderData: NodeConvertible {

    public let uid: String?
    public let displayName: String
    public let photoURL: String?
    public let email: String
    public let providerId: String?

    init(node: Node) throws {
        uid = try node.get("uid")
        displayName = try node.get("displayName")
        photoURL = try node.get("photoURL")
        email = try node.get("email")
        providerId = try node.get("providerId")
    }

    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "displayName" : .string(displayName),
            "email" : .string(email),
        ]).add(objects: [
            "uid" : uid,
            "photoURL" : photoURL,
            "providerId" : providerId
        ])
    }
}

final class JWTCredentials {

    public let token: String
    public let subject: String
    public let providerData: ProviderData?

    public init(token: String, subject: String, providerData: Node?) throws {
        self.token = token
        self.subject = subject
        self.providerData = try? ProviderData(node: providerData)
    }
}

extension JSON {

    var jwt: JWTCredentials? {
        guard let token = self["token"]?.string, let subject = self["subject"]?.string else {
            return nil
        }

        let providerData = self["providerData"]?.node

        return try? JWTCredentials(token: token, subject: subject, providerData: providerData)
    }
}

final class AuthenticationCollection {
    
    typealias Wrapped = HTTP.Responder
    
    func build(_ builder: RouteBuilder) {
        
        // TODO : jwt
    }
}

extension Request {

    var sessionType: SessionType {
        if (try? customer()) != nil {
            return .customer
        } else if (try? maker()) != nil {
            return .maker
        } else {
            return .none
        }
    }
}
