//
//  Vendor.swift
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
import Foundation
import Sanitized

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

final class Vendor: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted: [String] = ["contactName", "businessName", "parentCompanyName", "contactPhone", "contactEmail", "supportEmail", "publicWebsite", "dateCreated", "established", "category_id", "estimatedTotalSubscribers", "applicationState", "username", "password", "verificationState0", "stripeAccountId", "cut", "address"]
    
    var id: Node?
    var exists = false

    let contactName: String
    let contactPhone: String
    let contactEmail: String
    var applicationState: ApplicationState = .none
    var verificationState: LegalEntityVerificationStatus?
    
    let publicWebsite: String
    let supportEmail: String
    let businessName: String
    
    let parentCompanyName: String
    let established: String
    
    var category_id: Node?
    let estimatedTotalSubscribers: Int
    
    let dateCreated: Date

    var username: String
    var password: String
    var salt: BCryptSalt

    var stripeAccountId: String?
    
    let cut: Double
    
    var missingFields: Bool
    var needsIdentityUpload: Bool
    
    var keys: Keys?
    
    var address_id: Node?
    
    init(node: Node, in context: Context) throws {
        
        id = try? node.extract("id")
        
        applicationState = try node.extract("applicationState")
        
        username = try node.extract("username")
        let password = try node.extract("password") as String
        
        if let salt = try? node.extract("salt") as String {
            self.salt = try BCryptSalt(string: salt)
            self.password = password
        } else {
            self.salt = BCryptSalt()
            self.password = BCrypt.hash(password: password, salt: salt)
        }
        
        contactName = try node.extract("contactName")
        businessName = try node.extract("businessName")
        parentCompanyName = try node.extract("parentCompanyName")
        
        contactPhone = try node.extract("contactPhone")
        contactEmail = try node.extract("contactEmail")
        supportEmail = try node.extract("supportEmail")
        publicWebsite = try node.extract("publicWebsite")
        
        established = try node.extract("established")
        dateCreated = (try? node.extract("dateCreated")) ?? Date()
        
        estimatedTotalSubscribers = try node.extract("estimatedTotalSubscribers")
        
        category_id = try node.autoextract(type: Category.self, key: "category")
        address_id = try node.autoextract(type: VendorAddress.self, key: "address")
        
        cut = (try? node.extract("cut")) ?? 0.08
        stripeAccountId = try? node.extract("stripeAccountId")
        verificationState = try? node.extract("verificationState")
        
        missingFields = try (node.extract("missingFields") ?? false)
        needsIdentityUpload = try (node.extract("needsIdentityUpload") ?? false)
        
        if stripeAccountId != nil {
            let publishable: String = try node.extract("publishableKey")
            let secret: String = try node.extract("secretKey")
            
            keys = try Keys(node: Node(node: ["secret" : secret, "publishable" : publishable]))
        }
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "contactName" : .string(contactName),
            "businessName" : .string(businessName),
            "parentCompanyName" : .string(parentCompanyName),
            "applicationState" : applicationState.makeNode(),
            
            "contactPhone" : .string(contactPhone),
            "contactEmail" : .string(contactEmail),
            "supportEmail" : .string(supportEmail),
            "publicWebsite" : .string(publicWebsite),
            "estimatedTotalSubscribers" : .number(.int(estimatedTotalSubscribers)),
            
            "established" : .string(established),
            "dateCreated" : .string(dateCreated.ISO8601String),
            
            "username" : .string(username),
            "password": .string(password),
            "salt" : .string(salt.string),
            
            "missingFields" : .bool(missingFields),
            "needsIdentityUpload" : .bool(needsIdentityUpload)
        ]).add(objects: [
            "id" : id,
             "category_id" : category_id,
             "cut" : cut,
             "verificationState" : verificationState,
             "stripeAccountId" : stripeAccountId,
             "publishableKey" : keys?.publishable,
             "secretKey" : keys?.secret,
             "address_id" : address_id
        ])
    }
    
    func postValidate() throws {
        guard (try? category().first()) ?? nil != nil else {
            throw ModelError.missingLink(from: Vendor.self, to: Category.self, id: category_id?.int)
        }
        
        guard (try? address().first()) ?? nil != nil else {
            throw ModelError.missingLink(from: Vendor.self, to: VendorAddress.self, id: address_id?.int)
        }
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { vendor in
            vendor.id()
            vendor.string("contactName")
            vendor.string("businessName")
            vendor.string("parentCompanyName")
            vendor.string("contactPhone")
            vendor.string("contactEmail")
            vendor.double("supportEmail")
            vendor.string("publicWebsite")
            vendor.double("cut")
            vendor.string("estimatedTotalSubscribers")
            vendor.string("established")
            vendor.bool("missingFields")
            vendor.bool("needsIdentityUpload")
            vendor.string("dateCreated")
            vendor.string("stripeAccountId")
            vendor.string("username")
            vendor.string("password")
            vendor.string("salt")
            vendor.double("applicationState")
            vendor.string("verificationState")
            vendor.string("publishableKey")
            vendor.string("secretKey")
            vendor.parent(Category.self, optional: false)
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
            throw Abort.custom(status: .internalServerError, message: "Can not duplicate account onto vendor connect account if it has not been created on the platform first.")
        }
        
        guard let secretKey = keys?.secret else {
            throw Abort.custom(status: .internalServerError, message: "Missing secret key for vendor with id \(id?.int ?? 0)")
        }
        
        if let connectAccountCustomer = try self.connectAccountCustomers().filter("customer_id", customer_id).first() {
            
            let hasPaymentMethod = try Stripe.shared.paymentInformation(for: connectAccountCustomer.connectAccountCustomerId, under: secretKey).filter { $0.id == card }.count > 0
            
            if !hasPaymentMethod {
                let token = try Stripe.shared.createToken(for: connectAccountCustomer.connectAccountCustomerId, representing: card, on: secretKey)
                let _ = try Stripe.shared.associate(source: token.id, withStripe: connectAccountCustomer.connectAccountCustomerId, under: secretKey)
            }
            
            return connectAccountCustomer.connectAccountCustomerId
        } else {
            let token = try Stripe.shared.createToken(for: stripeCustomerId, representing: card, on: secretKey)
            let stripeCustomer = try Stripe.shared.createStandaloneAccount(for: customer, from: token, on: secretKey)
            
            var vendorCustomer = try VendorCustomer(vendor: self, customer: customer, account: stripeCustomer.id)
            try vendorCustomer.save()
            
            return vendorCustomer.connectAccountCustomerId
        }
    }
}

extension Entity {
    public func fix_children<T: Entity>(_ child: T.Type = T.self) -> Children<T> {
        return Children(parent: self, foreignKey: "\(Self.name)_\(Self.idKey)")
    }
}

extension Vendor {
    
    func boxes() -> Children<Box> {
        return fix_children()
    }
    
    func category() throws -> Parent<Category> {
        return try parent(category_id)
    }
    
    func connectAccountCustomers() throws -> Children<VendorCustomer> {
        return fix_children()
    }
    
    func address() throws -> Parent<VendorAddress> {
        return try parent(address_id)
    }
}

extension Vendor: Relationable {

    typealias Relations = (boxes: [Box], category: Category)
    
    func relations() throws -> (boxes: [Box], category: Category) {
        let boxes = try self.boxes().all()
        
        guard let category = try self.category().get() else {
            throw Abort.custom(status: .internalServerError, message: "Missing category relation for vendor with name \(username)")
        }
        
        return (boxes, category)
    }
}

extension Vendor: User {
    
    static func authenticate(credentials: Credentials) throws -> Auth.User {
        
        switch credentials {
            
        case let token as AccessToken:
            let session = try Session.session(forToken: token, type: .vendor)
            
            guard let vendor = try session.vendor().get() else {
                throw AuthError.invalidCredentials
            }
            
            return vendor
            
        case let usernamePassword as UsernamePassword:
            let query = try Vendor.query().filter("username", usernamePassword.username)
            
            guard let vendors = try? query.all() else {
                throw AuthError.invalidCredentials
            }
            
            if vendors.count > 0 {
                Droplet.logger?.error("found multiple accounts with the same username \(vendors.map { $0.id?.int ?? 0 })")
            }
            
            guard let vendor = vendors.first else {
                throw AuthError.invalidCredentials
            }
            
            if vendor.password == BCrypt.hash(password: usernamePassword.password, salt: vendor.salt) {
                return vendor
            } else {
                throw AuthError.invalidBasicAuthorization
            }
            
        default:
            throw AuthError.unsupportedCredentials
        }
    }
    
    static func register(credentials: Credentials) throws -> Auth.User {
        throw Abort.custom(status: .badRequest, message: "Register not supported.")
    }
}
