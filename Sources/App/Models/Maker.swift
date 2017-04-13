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

final class Maker: Model, Preparation, JSONConvertible, NodeConvertible, Sanitizable, JWTInitializable, SessionPersistable {

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
    let address_id: Identifier?
    
    let location: String
    let createdOn: Date
    let cut: Double
    
    var username: String
    var password: String?
    var hash: String
    
    var stripe_id: String?
    var keys: Keys?
    
    var missingFields: Bool
    var needsIdentityUpload: Bool
    
    var sub_id: String?

    init(subject: String, request: Request) throws {
        fatalError("Not supported")
    }
    
    init(node: Node) throws {
        
        id = try? node.extract("id")
        
        username = try node.extract("username")
        password = try? node.extract("password")

        if let password = try? node.extract("password") as String {
            self.hash = try Hash.make(message: password.makeBytes(), with: Salt()).string()
        } else {
            self.hash = try node.extract("hash") as String
        }
        
        email = try node.extract("email")
        businessName = try node.extract("businessName")
        publicWebsite = try node.extract("publicWebsite")
        
        contactName = try node.extract("contactName")
        contactPhone = try node.extract("contactPhone")
        contactEmail = try node.extract("contactEmail")
        address_id = try? node.extract("address_id")
        
        location = try node.extract("location")
        createdOn = (try? node.extract("createdOn")) ?? Date()
        cut = try node.extract("cut") ?? 0.08
        sub_id = try? node.extract("sub_id")
        
        stripe_id = try? node.extract("stripe_id")
        
        missingFields = (try? node.extract("missingFields")) ?? false
        needsIdentityUpload = (try? node.extract("needsIdentityUpload")) ?? false
        
        if stripe_id != nil {
            let publishable: String = try node.extract("publishableKey")
            let secret: String = try node.extract("secretKey")
            
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
            "cut" : .number(.double(cut)),
            
            "username" : .string(username),
            "hash" : .string(hash),
            
            "missingFields" : .bool(missingFields),
            "needsIdentityUpload" : .bool(needsIdentityUpload)
        ]).add(objects: [
            "id" : id,
             "stripe_id" : stripe_id,
             "publishableKey" : keys?.publishable,
             "secretKey" : keys?.secret,
             "address_id" : address_id,
             "sub_id" : sub_id,
             "createdOn" : Node.date(createdOn).string,
             "password" : (context?.isRow ?? false) ? password : nil
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
            maker.parent(idKey: "address_id", idType: .int, optional: true)
            
            maker.string("location")
            maker.string("createdOn")
            maker.double("cut")
            
            maker.string("username")
            maker.string("password")
            maker.string("hash")
            
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
        return parent(id: address_id)
    }

    func orders() -> Children<Maker, Order> {
        return children()
    }

    func sessions() -> Children<Maker, MakerSessionToken> {
        return children()
    }
}

import HTTP

final class MakerSessionToken: Model, Preparation, JSONConvertible, NodeConvertible {

    let storage = Storage()

    var id: Identifier?

    let maker_id: Identifier
    let token: String

    init(node: Node) throws  {
        maker_id = try node.extract("maker_id")
        token = try node.extract("token")
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

    var hashedPassword: String? {
        return self.hash
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
