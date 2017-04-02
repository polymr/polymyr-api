//
//  Maker.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent
import FluentProvider
import BCrypt
import Foundation
import Node
import AuthProvider

extension Hash: PasswordVerifier {

    public func verify(password: String, matchesHash: String) throws -> Bool {
        return try Hash.verify(message: password, matches: matchesHash.makeBytes())
    }
}

enum ApplicationState: String, NodeConvertible {
    
    case none = "none"
    case recieved = "recieved"
    case rejected = "rejected"
    case accepted = "accepted"
    
    init(node: Node) throws {
        
        guard let state = node.string.flatMap ({ ApplicationState(rawValue: $0) }) else {
            throw Abort.custom(status: .badRequest, message: "Invalid value for application state.")
        }
        
        self = state
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return .string(rawValue)
    }
}

extension Salt: NodeInitializable {
    
    public init(node: Node) throws {

        guard let salt = try node.string.flatMap({ try Salt(bytes: $0.makeBytes()) }) else {
            throw Abort.custom(status: .badRequest, message: "Invalid salt.")
        }

        self = salt
    }
}

final class Maker: Model, Preparation, JSONConvertible, NodeConvertible, Sanitizable {

    let storage = Storage()
    
    static var permitted: [String] = ["email", "businessName", "publicWebsite", "contactName", "contactPhone", "contactEmail", "location", "createdOn", "cut", "username", "stripe_id", "keys", "missingFields", "needsIdentityUpload", "address_id", "password"]
    
    var id: Identifier?
    var exists = false
    
    let email: String
    let businessName: String
    let publicWebsite: String

    let contactName: String
    let contactPhone: String
    let contactEmail: String
    let address_id: Identifier
    
    let location: String
    let createdOn: Date
    let cut: Double
    
    var username: String
    var password: String?
    var pass: String?
    var hashedPassword: String
    
    var stripe_id: String?
    var keys: Keys?
    
    var missingFields: Bool
    var needsIdentityUpload: Bool
    
    var sub_id: String?
    
    init(node: Node) throws {
        
        id = try node.get("id")
        
        username = try node.get("username")
        pass = password

        if let password = try? node.get("password") as String {
            self.hashedPassword = try Hash.make(message: password.makeBytes(), with: Salt()).string()
        } else {
            self.hashedPassword = try node.get("hashedPassword") as String
        }
        
        email = try node.get("email")
        businessName = try node.get("businessName")
        publicWebsite = try node.get("publicWebsite")
        
        contactName = try node.get("contactName")
        contactPhone = try node.get("contactPhone")
        contactEmail = try node.get("contactEmail")
        address_id = try node.get("address_id")
        
        location = try node.get("location")
        createdOn = try node.get("createdOn") ?? Date()
        cut = try node.get("cut") ?? 0.08
        sub_id = try node.get("sub_id")
        
        stripe_id = try node.get("stripe_id")
        
        missingFields = (try? node.get("missingFields")) ?? false
        needsIdentityUpload = (try? node.get("needsIdentityUpload")) ?? false
        
        if stripe_id != nil {
            let publishable: String = try node.get("publishableKey")
            let secret: String = try node.get("secretKey")
            
            keys = try Keys(node: Node(node: ["secret" : secret, "publishable" : publishable]))
        }
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "email" : .string(email),
            "businessName" : .string(businessName),
            "publicWebsite" : .string(publicWebsite),
            
            "contactName" : .string(contactName),
            "contactPhone" : .string(contactPhone),
            "contactEmail" : .string(contactEmail),
            
            "location" : .string(location),
            "createdOn" : .string(createdOn.ISO8601String),
            "cut" : .number(.double(cut)),
            
            "username" : .string(username),
            "hashedPassword" : .string(hashedPassword),
            
            "missingFields" : .bool(missingFields),
            "needsIdentityUpload" : .bool(needsIdentityUpload)
        ]).add(objects: [
            "id" : id,
             "stripe_id" : stripe_id,
             "publishableKey" : keys?.publishable,
             "secretKey" : keys?.secret,
             "address_id" : address_id,
             "sub_id" : sub_id,
             "pass" : pass,
        ])
    }
    
    func postValidate() throws {
        // TODO
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Maker.self) { maker in
            maker.id(for: Maker.self)
            maker.string("email")
            maker.string("businessName")
            maker.string("publicWebsite")
            
            maker.string("contactName")
            maker.string("contactPhone")
            maker.string("contactEmail")
            maker.parent(idKey: "address_id", idType: .int)
            
            maker.string("location")
            maker.string("createdOn")
            maker.double("cut")
            
            maker.string("google_id", optional: true)
            maker.string("facebook_id", optional: true)
            
            maker.string("username")
            maker.string("password")
            maker.string("salt")
            
            maker.string("publishableKey", optional: true)
            maker.string("secretKey", optional: true)
            maker.string("sub_id", optional: true)
            
            maker.string("stripe_id", optional: true)
            maker.bool("missingFields")
            maker.bool("needsIdentityUpload")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Maker.self)
    }
    
    func fetchConnectAccount(for customer: Customer, with card: String) throws -> String {
        guard let customer_id = customer.id else {
            throw Abort.custom(status: .internalServerError, message: "Asked to find connect account customer for customer with no id.")
        }
        
        guard let stripeCustomerId = customer.stripe_id else {
            throw Abort.custom(status: .internalServerError, message: "Can not duplicate account onto maker connect account if it has not been created on the platform first.")
        }
        
        guard let secretKey = keys?.secret else {
            throw Abort.custom(status: .internalServerError, message: "Missing secret key for maker with id \(id?.int ?? 0)")
        }
        
        if let connectAccountCustomer = try self.connectAccountCustomers().filter("customer_id", customer_id).filter("maker_id", self.throwableId()).first() {
            
            let hasPaymentMethod = try Stripe.shared.paymentInformation(for: connectAccountCustomer.stripeCustomerId, under: secretKey).filter { $0.id == card }.count > 0
            
            if !hasPaymentMethod {
                let token = try Stripe.shared.createToken(for: connectAccountCustomer.stripeCustomerId, representing: card, on: secretKey)
                let _ = try Stripe.shared.associate(source: token.id, withStripe: connectAccountCustomer.stripeCustomerId, under: secretKey)
            }
            
            return connectAccountCustomer.stripeCustomerId
        } else {
            let token = try Stripe.shared.createToken(for: stripeCustomerId, representing: card, on: secretKey)
            let stripeCustomer = try Stripe.shared.createStandaloneAccount(for: customer, from: token, on: secretKey)
            
            let makerCustomer = try StripeMakerCustomer(maker: self, customer: customer, account: stripeCustomer.id)
            try makerCustomer.save()
            
            return makerCustomer.stripeCustomerId
        }
    }
}

extension Maker {
    
    func products() -> Children<Maker, Product> {
        return children()
    }
    
    func connectAccountCustomers() throws -> Children<Maker, StripeMakerCustomer> {
        return children()
    }
    
    func address() -> Parent<Maker, MakerAddress> {
        return parent(id: "address_id")
    }

    func orders() -> Children<Maker, Order> {
        return children()
    }

    func sessions() -> Children<Maker, MakerSessionToken> {
        return children()
    }
}

import HTTP

private let sessionEntityId = "maker-session"

extension Maker: SessionPersistable {

    public func persist(for req: Request) throws {
        try req.session().data.set(sessionEntityId, id)
    }

    public func unpersist(for req: Request) throws {
        try req.session().data.set(sessionEntityId, nil)
    }

    public static func fetchPersisted(for request: Request) throws -> Customer? {
        guard let id = try request.session().data[sessionEntityId] else {
            return nil
        }

        guard let user = try Customer.find(id) else {
            return nil
        }

        return user
    }
}

final class MakerSessionToken: Model, Preparation, JSONConvertible, NodeConvertible {

    let storage = Storage()

    var id: Identifier?

    let maker_id: Identifier
    let token: String

    init(node: Node) throws  {
        maker_id = try node.get("maker_id")
        token = try node.get("token")
    }

    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "token" : token
        ]).add(objects: [
            "maker_id" : maker_id
        ])
    }

    static func prepare(_ database: Database) throws {
        try database.create(MakerSessionToken.self) { session in
            session.id(for: MakerSessionToken.self)
            session.parent(idKey: "maker_id", idType: .int)
            session.string("token")
        }
    }

    static func revert(_ database: Database) throws {
        try database.delete(MakerSessionToken.self)
    }
}

extension Maker: TokenAuthenticatable {

    typealias TokenType = MakerSessionToken

    public static var tokenKey: String {
        return "token"
    }
}

struct MakerPasswordVerifier: PasswordVerifier {

    func verify(password: String, matchesHash: String) throws -> Bool {
        return try Hash.verify(message: password, matches: matchesHash.makeBytes())
    }
}

extension Maker: PasswordAuthenticatable {

    public static var usernameKey: String {
        return "username"
    }

    public static var passwordVerifier: PasswordVerifier? {
        return MakerPasswordVerifier()
    }
    
//    static func authenticate(credentials: Credentials) throws -> Auth.User {
//        
//        switch credentials {
//            
//        case let token as AccessToken:
//            guard let _maker = try? Session.session(forToken: token, type: .maker).maker().first(), let maker = _maker else {
//                throw AuthError.invalidCredentials
//            }
//            
//            return maker
//
//        case let usernamePassword as UsernamePassword:
//            guard let _maker = try? Maker.query().filter("username", usernamePassword.username).first(), let maker = _maker else {
//                throw AuthError.invalidCredentials
//            }
//            
//            guard let result = try? BCrypt.verify(password: usernamePassword.password, matchesHash: maker.password), result else {
//                throw AuthError.invalidCredentials
//            }
//            
//            return maker
//
//        case let jwt as JWTCredentials:
//            if jwt.subject.hasPrefix("__force__") {
//                if let _user = try? Customer.query().filter("sub_id", jwt.subject).first(), let user = _user {
//                    return user
//                }
//            }
//
//            guard let ruby = drop.config["servers", "default", "ruby"]?.string else {
//                throw Abort.custom(status: .internalServerError, message: "Missing path to ruby executable")
//            }
//
//            let result: String
//
//            do {
//                result = try drop.console.backgroundExecute(program: ruby, arguments: [drop.workDir + "identity/verifiy_identity.rb", jwt.token, jwt.subject, drop.workDir])
//            } catch {
//                throw Abort.custom(status: .internalServerError, message: "Failed to decode token. \(error)")
//            }
//
//            drop.console.info("ruby result : \(result)")
//
//            guard result == "success" else {
//                print(result)
//                throw AuthError.invalidCredentials
//            }
//
//            guard let _maker = try? Maker.query().filter("sub_id", jwt.subject).first(), let maker = _maker else {
//                throw AuthError.invalidCredentials
//            }
//
//            return maker
//        default:
//            throw AuthError.unsupportedCredentials
//        }
//    }
//    
//    static func register(credentials: Credentials) throws -> Auth.User {
//        throw Abort.custom(status: .badRequest, message: "Register not supported.")
//    }
}
