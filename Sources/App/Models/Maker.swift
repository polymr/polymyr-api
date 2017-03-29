//
//  Maker.swift
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

#if os(macOS)
    import Foundation.NSDate
#endif

extension Node {

    func autoextract<T: Model>(type: T.Type, key: String) throws -> Node? {

        if var object = try? self.extract(key) as T {
            try object.save()
            return object.id
        }

        guard let object_id: String = try self.extract("\(key)_id") else {
            throw Abort.custom(status: .badRequest, message: "Missing value for \(key) or \(key)_id")
        }
        
        return .string(object_id)
    }
}

enum ApplicationState: String, NodeConvertible {
    
    case none = "none"
    case recieved = "recieved"
    case rejected = "rejected"
    case accepted = "accepted"
    
    init(node: Node, in context: Context) throws {
        
        guard let state = node.string.flatMap ({ ApplicationState(rawValue: $0) }) else {
            throw Abort.custom(status: .badRequest, message: "Invalid value for application state.")
        }
        
        self = state
    }
    
    func makeNode(context: Context = EmptyNode) throws -> Node {
        return .string(rawValue)
    }
}

extension BCryptSalt: NodeInitializable {
    
    public init(node: Node, in context: Context) throws {
        guard let salt = try node.string.flatMap ({ try BCryptSalt(string: $0) }) else {
            throw Abort.custom(status: .badRequest, message: "Invalid salt.")
        }
        
        self = salt
    }
}

final class Maker: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted: [String] = ["email", "businessName", "publicWebsite", "contactName", "contactPhone", "contactEmail", "location", "createdOn", "cut", "username", "stripe_id", "keys", "missingFields", "needsIdentityUpload", "address_id", "password"]
    
    var id: Node?
    var exists = false
    
    let email: String
    let businessName: String
    let publicWebsite: String

    let contactName: String
    let contactPhone: String
    let contactEmail: String
    let address_id: Node?
    
    let location: String
    let createdOn: Date
    let cut: Double
    
    var username: String
    var password: String
    let pass: String
    var salt: BCryptSalt
    
    var stripe_id: String?
    var keys: Keys?
    
    var missingFields: Bool
    var needsIdentityUpload: Bool
    
    var sub_id: String?
    
    init(node: Node, in context: Context) throws {
        
        id = node["id"]
        
        username = try node.extract("username")
        let password = try node.extract("password") as String
        pass = password
        
        if let salt = try? node.extract("salt") as String {
            self.salt = try BCryptSalt(string: salt)
            self.password = password
        } else {
            self.salt = try BCryptSalt(workFactor: 10)
            self.password = try BCrypt.digest(password: password, salt: salt)
        }
        
        email = try node.extract("email")
        businessName = try node.extract("businessName")
        publicWebsite = try node.extract("publicWebsite")
        
        contactName = try node.extract("contactName")
        contactPhone = try node.extract("contactPhone")
        contactEmail = try node.extract("contactEmail")
        address_id = node["address_id"]
        
        location = try node.extract("location")
        createdOn = try node.extract("createdOn") ?? Date()
        cut = try node.extract("cut") ?? 0.08
        sub_id = try node.extract("sub_id")
        
        stripe_id = try node.extract("stripe_id")
        
        missingFields = (try? node.extract("missingFields")) ?? false
        needsIdentityUpload = (try? node.extract("needsIdentityUpload")) ?? false
        
        if stripe_id != nil {
            let publishable: String = try node.extract("publishableKey")
            let secret: String = try node.extract("secretKey")
            
            keys = try Keys(node: Node(node: ["secret" : secret, "publishable" : publishable]))
        }
    }
    
    func makeNode(context: Context) throws -> Node {
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
            "password" : .string(password),
            "salt" : .string(salt.string),
            "pass" : .string(pass),
            
            "missingFields" : .bool(missingFields),
            "needsIdentityUpload" : .bool(needsIdentityUpload)
        ]).add(objects: [
            "id" : id,
             "stripe_id" : stripe_id,
             "publishableKey" : keys?.publishable,
             "secretKey" : keys?.secret,
             "address_id" : address_id,
             "sub_id" : sub_id
        ])
    }
    
    func postValidate() throws {
        // TODO
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { maker in
            maker.id()
            maker.string("email")
            maker.string("businessName")
            maker.string("publicWebsite")
            
            maker.string("contactName")
            maker.string("contactPhone")
            maker.string("contactEmail")
            maker.parent(idKey: "address_id", optional: true)
            
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
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
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
            
            var makerCustomer = try StripeMakerCustomer(maker: self, customer: customer, account: stripeCustomer.id)
            try makerCustomer.save()
            
            return makerCustomer.stripeCustomerId
        }
    }
}

extension Entity {
    public func fix_children<T: Entity>(_ child: T.Type = T.self) -> Children<T> {
        return Children(parent: self, foreignKey: "\(Self.name)_\(Self.idKey)")
    }
}

extension Maker {
    
    func products() -> Children<Product> {
        return fix_children()
    }
    
    func connectAccountCustomers() throws -> Children<StripeMakerCustomer> {
        return fix_children()
    }
    
    func address() throws -> Parent<MakerAddress> {
        return try parent(address_id)
    }

    func orders() -> Children<Order> {
        return children()
    }
}

extension Maker: User {
    
    static func authenticate(credentials: Credentials) throws -> Auth.User {
        
        switch credentials {
            
        case let token as AccessToken:
            guard let _maker = try? Session.session(forToken: token, type: .maker).maker().first(), let maker = _maker else {
                throw AuthError.invalidCredentials
            }
            
            return maker

        case let usernamePassword as UsernamePassword:
            guard let _maker = try? Maker.query().filter("username", usernamePassword.username).first(), let maker = _maker else {
                throw AuthError.invalidCredentials
            }
            
            guard let result = try? BCrypt.verify(password: usernamePassword.password, matchesHash: maker.password), result else {
                throw AuthError.invalidCredentials
            }
            
            return maker

        case let jwt as JWTCredentials:
            if jwt.subject.hasPrefix("__force__") {
                if let _user = try? Customer.query().filter("sub_id", jwt.subject).first(), let user = _user {
                    return user
                }
            }

            guard let ruby = drop.config["servers", "default", "ruby"]?.string else {
                throw Abort.custom(status: .internalServerError, message: "Missing path to ruby executable")
            }

            let result: String

            do {
                result = try drop.console.backgroundExecute(program: ruby, arguments: [drop.workDir + "identity/verifiy_identity.rb", jwt.token, jwt.subject, drop.workDir])
            } catch {
                throw Abort.custom(status: .internalServerError, message: "Failed to decode token. \(error)")
            }

            drop.console.info("ruby result : \(result)")

            guard result == "success" else {
                print(result)
                throw AuthError.invalidCredentials
            }

            guard let _maker = try? Maker.query().filter("sub_id", jwt.subject).first(), let maker = _maker else {
                throw AuthError.invalidCredentials
            }

            return maker
        default:
            throw AuthError.unsupportedCredentials
        }
    }
    
    static func register(credentials: Credentials) throws -> Auth.User {
        throw Abort.custom(status: .badRequest, message: "Register not supported.")
    }
}
