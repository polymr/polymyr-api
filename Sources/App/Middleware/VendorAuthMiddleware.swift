//
//  VendorAuthMiddleware.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/10/16.
//
//

import Turnstile
import HTTP
import Cookies
import Foundation
import Cache
import Auth
import Vapor

private let cookieName = "vapor-vendor-auth"
private let storageName = "vendorSubject"
private let cookieTimeout: TimeInterval = 7 * 24 * 60 * 60

extension Request {
    
    func vendorSubject() throws -> Subject {
        guard let subject = storage[storageName] as? Subject else {
            throw AuthError.noSubject
        }
        
        return subject
    }
}

public class VendorAuthMiddleware: Middleware {

    private let turnstile: Turnstile
    private let cookieFactory: CookieFactory
    
    public typealias CookieFactory = (String) -> Cookie
    
    init() {
        let realm = AuthenticatorRealm<Vendor>()
        self.turnstile = Turnstile(sessionManager: DatabaseLoginSessionManager(realm: realm), realm: realm)
        
        self.cookieFactory = { value in
            return Cookie(
                name: cookieName,
                value: value,
                expires: Date().addingTimeInterval(cookieTimeout),
                secure: false,
                httpOnly: true
            )
        }
    }

    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        request.storage[storageName] = Subject(
            turnstile: turnstile,
            sessionID: request.cookies[cookieName]
        )
        
        let response = try next.respond(to: request)
        let session = try request.vendorSubject().authDetails?.sessionID
        
        if let session = session, request.cookies[cookieName] != session {
            response.cookies.insert(cookieFactory(session))
        } else if session == nil && request.cookies[cookieName] != nil {
            // If we have a cookie but no session, delete it.
            response.cookies[cookieName] = nil
        }
        
        return response
    }
}

public class VendorProtectMiddleware: Middleware {
    
    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        guard try request.vendorSubject().authenticated else {
            throw Abort.custom(status: .forbidden, message: "No vendor subject.")
        }
        
        return try next.respond(to: request)
    }
}
