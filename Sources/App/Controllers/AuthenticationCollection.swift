//
//  AuthenticationController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import HTTP
import Turnstile
import Auth
import Fluent
import Routing

final class ProviderData: NodeConvertible {

    public let uid: String?
    public let displayName: String
    public let photoURL: String?
    public let email: String
    public let providerId: String?

    init(node: Node, in context: Context = EmptyNode) throws {
        uid = try node.extract("uid")
        displayName = try node.extract("displayName")
        photoURL = try node.extract("photoURL")
        email = try node.extract("email")
        providerId = try node.extract("providerId")
    }

    func makeNode(context: Context = EmptyNode) throws -> Node {
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

final class JWTCredentials: Credentials {

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

final class AuthenticationCollection: RouteCollection {
    
    typealias Wrapped = HTTP.Responder
    
    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {
        
        builder.post("authentication") { request in
            
            let type = try request.extract() as SessionType

            guard let credentials: Credentials = request.auth.header?.usernamePassword ?? request.json?.jwt else {
                throw AuthError.invalidCredentials
            }
            
            switch type {
            case .customer:
                try request.userSubject().login(credentials: credentials, persist: true)
            case .maker:
                try request.makerSubject().login(credentials: credentials, persist: true)
            case .none:
                throw Abort.custom(status: .badRequest, message: "Can not log in with a session type of none.")
            }
            
            let modelSubject: JSONConvertible = type == .customer ? try request.customer() : try request.maker()
            return try Response(status: .ok, json: modelSubject.makeJSON())
        }
    }
}

extension Authorization {
    public var usernamePassword: UsernamePassword? {
        guard let range = header.range(of: "Basic ") else {
            return nil
        }
        
        let authString = header.substring(from: range.upperBound)
        
        guard let decodedAuthString = try? authString.base64Decoded.string() else {
            return nil
        }
        
        guard let separatorRange = decodedAuthString.range(of: ":") else {
            return nil
        }
        
        let username = decodedAuthString.substring(to: separatorRange.lowerBound)
        let password = decodedAuthString.substring(from: separatorRange.upperBound)
        
        return UsernamePassword(username: username, password: password)
    }
}

extension Request {
    
    func has(session type: SessionType) -> Bool {
        switch type {
        case .customer:
            return (try? customer()) != nil
        case .maker:
            return (try? maker()) != nil
        case .none:
            return type == .none
        }
    }
    
    var sessionType: SessionType {
        if (try? customer()) != nil {
            return .customer
        } else if (try? maker()) != nil {
            return .maker
        } else {
            return .none
        }
    }
    
    func customer() throws -> Customer {
        let subject = try userSubject()
        
        guard let details = subject.authDetails else {
            throw AuthError.notAuthenticated
        }
        
        guard let customer = details.account as? Customer else {
            throw AuthError.invalidAccountType
        }
        
        return customer
    }
    
    func maker() throws -> Maker {
        let subject = try makerSubject()
        
        guard let details = subject.authDetails else {
            throw AuthError.notAuthenticated
        }
        
        guard let maker = details.account as? Maker else {
            throw AuthError.invalidAccountType
        }
        
        return maker
    }
}
