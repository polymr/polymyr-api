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

extension Request {
    
    var baseURL: String {
        return uri.scheme + "://" + uri.host + (uri.port == nil ? "" : ":\(uri.port!)")
    }
}

final class AuthenticationCollection: RouteCollection {
    
    let facebook: Facebook
    let google: Google
    
    required init() throws {
        guard let fb = drop.config["oauth", "facebook"], let fb_id: String = try fb.extract("id"), let fb_secret: String = try fb.extract("secret") else {
            throw Abort.custom(status: .internalServerError, message: "Missing facebook configuration.")
        }
        
        facebook = Facebook(clientID: fb_id, clientSecret: fb_secret)
        
        guard let gl = drop.config["oauth", "google"], let gl_id: String = try gl.extract("id"), let gl_secret: String = try gl.extract("secret") else {
            throw Abort.custom(status: .internalServerError, message: "Missing facebook configuration.")
        }
        
        google = Google(clientID: gl_id, clientSecret: gl_secret)
    }
    
    typealias Wrapped = HTTP.Responder
    
    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {
        
        builder.post("login") { request in
            
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
        
        builder.group("oauth") { oauth in
            
            oauth.group("facebook") { fb_group in
                
                fb_group.get("login") { request in
                    let state = UUID().uuidString
                    let response = Response(redirect: self.facebook.getLoginLink(redirectURL: request.baseURL + "/oauth/facebook/callback", state: state).absoluteString)
                    response.cookies["OAuthState"] = state
                    return response
                }
                
                fb_group.get("callback") { request in
                    guard let state = request.cookies["OAuthState"] else {
                        throw Abort.custom(status: .internalServerError, message: "Missing state.")
                    }
                    
                    guard let account = try self.facebook.authenticate(authorizationCodeCallbackURL: request.uri.description, state: state) as? FacebookAccount else {
                        throw Abort.custom(status: .internalServerError, message: "Failed to create facebook account")
                    }
                    
                    try request.auth.login(account)
                    return "Ok"
                }
                
            }
            
            oauth.group("google") { gl_group in
                
                gl_group.get("login") { request in
                    let state = UUID().uuidString
                    let response = Response(redirect: self.google.getLoginLink(redirectURL: "/oauth/google/callback", state: state).absoluteString)
                    response.cookies["OAuthState"] = state
                    return response
                }
                
                gl_group.get("callback") { request in
                    guard let state = request.cookies["OAuthState"] else {
                        throw Abort.custom(status: .internalServerError, message: "Missing state.")
                    }
                    
                    guard let account = try self.facebook.authenticate(authorizationCodeCallbackURL: request.uri.description, state: state) as? FacebookAccount else {
                        throw Abort.custom(status: .internalServerError, message: "Failed to create google account")
                    }
                    
                    try request.auth.login(account)
                    return "Ok"
                }
            }
            
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
