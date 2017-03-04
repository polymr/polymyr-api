//
//  DatabaseSessionManager.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/28/16.
//
//

import Turnstile
import Random
import Cache
import Foundation

public final class DatabaseLoginSessionManager: SessionManager {

    private let realm: Realm
    
    public init(realm: Realm) {
        self.realm = realm
    }
    
    public func restoreAccount(fromSessionID identifier: String) throws -> Account {
        return try realm.authenticate(credentials: AccessToken(string: identifier))
    }
    
    /**
     Creates a session for a given Subject object and returns the identifier.
     */
    public func createSession(account: Account) -> String {
        let token = UUID().uuidString
        let type: SessionType = account is Vendor ? .vendor : .customer
        
        var session = Session(token: token, subject_id: account.uniqueID, type: type)
        
        // TODO: Error handling
        // https://github.com/stormpath/Turnstile/issues/18
        do {
            try session.save()
        } catch {
            fatalError("Error saving session \(error)")
        }
        
        return token
    }
    
    /**
     Destroys the session for a session identifier.
     */
    public func destroySession(identifier: String) {
        try? Session.query().filter("accessToken", identifier).first()?.delete()
    }
}
