//
//  AuthenticationController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Foundation
import Vapor
import HTTP
import Turnstile
import Auth
import Fluent

final class AuthenticationController: ResourceRepresentable {
    
    func login(_ request: Request) throws -> ResponseRepresentable {
        
        let type = try request.extract() as SessionType
        
        guard let credentials = request.auth.header?.usernamePassword else {
            throw AuthError.noAuthorizationHeader
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
    
    func makeResource() -> Resource<String> {
        return Resource(
            store: login
        )
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
