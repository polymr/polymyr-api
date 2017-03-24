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
import Routing
import TurnstileWeb

func shell(launchPath: String, arguments: String...) -> String? {
    let task = Process()
    task.launchPath = launchPath
    task.arguments = arguments

    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.launch()

    task.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)
}

extension Request {
    
    var baseURL: String {
        return uri.scheme + "://" + uri.host + (uri.port == nil ? "" : ":\(uri.port!)")
    }
}

final class JWTCredentials: Credentials {

    /// Username or email address
    public let token: String

    /// Password (unhashed)
    public let subject: String

    /// Initializer for PasswordCredentials
    public init(token: String, subject: String) {
        self.token = token
        self.subject = subject
    }
}

extension Request {

    func jwtCredentials() -> JWTCredentials? {
        guard let token = json?["token"]?.string, let subject = json?["subject"]?.string else {
            return nil
        }

        return JWTCredentials(token: token, subject: subject)
    }
}

final class AuthenticationCollection: RouteCollection {
    
    typealias Wrapped = HTTP.Responder
    
    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {
        
        builder.post("authentication") { request in
            
            let type = try request.extract() as SessionType

            var _credentials: Credentials? = request.auth.header?.usernamePassword
            _credentials = request.jwtCredentials()

            guard let credentials = _credentials else {
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
