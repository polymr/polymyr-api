//
//  File.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent
import Auth
import Turnstile
import BCrypt
import Sanitized
import TurnstileWeb

extension Stripe {
    
    func createStandaloneAccount(for customer: Customer, from source: Token, on account: String) throws -> StripeCustomer {
        guard let customerId = customer.id?.int else {
            throw Abort.custom(status: .internalServerError, message: "Missing customer id for customer. \(customer.prettyString)")
        }
        
        return try Stripe.shared.createNormalAccount(email: customer.email, source: source.id, local_id: customerId, on: account)
    }
}

final class Customer: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted: [String] = ["email", "name", "default_shipping_id", "password"]
    
    var id: Node?
    var exists = false
    
    let name: String
    let email: String
    let password: String
    let pass: String
    let salt: BCryptSalt

    var default_shipping_id: Node?
    var stripe_id: String?
    
    var google_id: String?
    var facebook_id: String?
    
    init(node: Node, in context: Context) throws {
        id = try? node.extract("id")
        default_shipping_id = try? node.extract("default_shipping_id")
        
        // Name and email are always mandatory
        email = try node.extract("email")
        name = try node.extract("name")
        stripe_id = try node.extract("stripe_id")
        google_id = try node.extract("google_id")
        facebook_id = try node.extract("facebook_id")
        
        let password = try node.extract("password") as String
        pass = password
         
        if let salt = try? node.extract("salt") as String {
            self.salt = try BCryptSalt(string: salt)
            self.password = password
        } else {
            self.salt = try BCryptSalt(workFactor: 10)
            self.password = try BCrypt.digest(password: password, salt: salt)
        }
    }
    
    func makeNode(context: Context = EmptyNode) throws -> Node {
        return try Node(node: [
            "name" : .string(name),
            "email" : .string(email),
            "password" : .string(password),
            "pass" : .string(pass),
            "salt" : .string(salt.string)
        ]).add(objects: [
            "id" : id,
            "stripe_id" : stripe_id,
            "default_shipping_id" : default_shipping_id,
            "google_id" : google_id,
            "facebook_id" : facebook_id
        ])
    }
    
    func postValidate() throws {
        if default_shipping_id != nil {
            guard (try? defaultShipping().first()) ?? nil != nil else {
                throw ModelError.missingLink(from: Customer.self, to: CustomerAddress.self, id: default_shipping_id?.int)
            }
        }
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity) { box in
            box.id()
            box.string("name")
            box.string("stripe_id", optional: true)
            box.string("email")
            box.string("password")
            box.string("salt")
            box.string("google_id", optional: true)
            box.string("facebook_id", optional: true)
            box.int("default_shipping_id", optional: true)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Customer {

    func defaultShipping() throws -> Parent<CustomerAddress> {
        return try parent(default_shipping_id)
    }
    
    func shippingAddresses() -> Children<CustomerAddress> {
        return fix_children()
    }
    
    func sessions() -> Children<Session> {
        return fix_children()
    }
}

extension Customer: User {
    
    static func authenticate(credentials: Credentials) throws -> Auth.User {
        
        switch credentials {
            
        case let token as AccessToken:
            guard let _user = try? Session.session(forToken: token, type: .customer).user().first(), let user = _user else {
                throw AuthError.invalidCredentials
            }
        
            return user
            
        case let usernamePassword as UsernamePassword:
            guard let _user = try? Customer.query().filter("email", usernamePassword.username).first(), let user = _user else {
                throw AuthError.invalidCredentials
            }
            
            guard let result = try? BCrypt.verify(password: usernamePassword.password, matchesHash: user.password), result else {
                throw AuthError.invalidCredentials
            }
            
            return user
            
        case let facebook as FacebookAccount:
            guard let _user = try? Customer.query().filter("facebook_id", facebook.uniqueID).first(), let user = _user else {
                throw AuthError.invalidCredentials
            }
            
            return user
        
        case let google as GoogleAccount:
            guard let _user = try? Customer.query().filter("google_id", google.uniqueID).first(), let user = _user else {
                throw AuthError.invalidCredentials
            }
            
            return user
            
        default:
            throw AuthError.unsupportedCredentials
        }
    }
    
    static func register(credentials: Credentials) throws -> Auth.User {
        throw Abort.custom(status: .badRequest, message: "Register not supported.")
    }
}

extension Model {
    
    func throwableId() throws -> Int {
        guard let id = id else {
            throw Abort.custom(status: .internalServerError, message: "Bad internal state. \(type(of: self).entity) does not have database id when it was requested.")
        }
        
        guard let customerIdInt = id.int else {
            throw Abort.custom(status: .internalServerError, message: "Bad internal state. \(type(of: self).entity) has database id but it was of type \(id.type) while we expected number.int")
        }
        
        return customerIdInt
    }
}
