//
//  AuthenticationController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import HTTP
import Fluent
import FluentProvider
import Routing
import Node
import JWT
import AuthProvider

enum SessionType: String, TypesafeOptionsParameter {
    case customer
    case maker
    case anonymous

    static let key = "type"
    static let values = [SessionType.customer.rawValue, SessionType.maker.rawValue]

    static var defaultValue: SessionType? = .none

    var type: Authenticatable.Type {
        switch self {
        case .customer:
            return Customer.self
        case .maker:
            return Maker.self
        case .anonymous:
            // TODO : figure this out
            return Customer.self
        }
    }
}

final class ProviderData: NodeConvertible {

    public let uid: String?
    public let displayName: String
    public let photoURL: String?
    public let email: String
    public let providerId: String?

    init(node: Node) throws {
        uid = try node.extract("uid")
        displayName = try node.extract("displayName")
        photoURL = try node.extract("photoURL")
        email = try node.extract("email")
        providerId = try node.extract("providerId")
    }

    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "displayName" : .string(displayName),
            "email" : .string(email),
        ]).add(objects: [
            "uid" : uid,
            "photoURL" : photoURL,
            "providerId" : providerId
        ])
    }
}

protocol JWTInitializable {

    init(subject: String, request: Request) throws
}

final class AuthenticationCollection {
    
    typealias AuthenticationSubject = Entity & Authenticatable & JWTInitializable & NodeConvertible & Persistable

    var keys: [String : String] = [:]
    
    func build(_ builder: RouteBuilder) {

        builder.grouped(PasswordAuthenticationMiddleware(Maker.self)).post("login") { request in
            return try request.auth.assertAuthenticated(Maker.self).makeResponse()
        }

        builder.post("authentication") { request in

            guard
                let token: String = try request.json?.extract("token"),
                let subject: String = try request.json?.extract("subject")
            else {
                throw AuthenticationError.notAuthenticated
            }

            // TODO : remove me
            if subject.hasPrefix("__force__") {
                let actual = subject.replacingOccurrences(of: "__force__", with: "")
                return try self.authenticateUserFor(subject: actual, with: request, create: false).makeResponse()
            }

            let jwt = try JWT(token: token)
            let key = try self.fetchSigningKey(for: jwt.headers.extract("kid") as String)

            // TODO : IssuedAtClaim should be in the past

            let signer = try RS256(key: key.bytes)

            let claims = [ExpirationTimeClaim(createTimestamp: { return Seconds(Date().timeIntervalSince1970) }, leeway: 60),
                          AudienceClaim(string: "polymyr-a5014"),
                          IssuerClaim(string: "https://securetoken.google.com/polymyr-a5014"),
                          SubjectClaim(string: subject)] as [Claim]

            do {
                try jwt.verifySignature(using: signer)
                try jwt.verifyClaims(claims)
            } catch {
                throw Abort.custom(status: .internalServerError, message: "Failed to verify JWT token with error : \(error)")
            }

            return try self.authenticateUserFor(subject: subject, with: request, create: true).makeResponse()
        }
    }

    func fetchSigningKey(for identifier: String) throws -> String {
        if let key = keys[identifier] {
            return key
        }

        let response = try drop.client.get("https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com")

        guard let fetchedKeys = response.json?.object else {
            throw Abort.custom(status: .internalServerError, message: "Could not get new signing keys.")
        }

        var newKeyLookup: [String : String] = [:]

        try fetchedKeys.forEach {
            guard let value = $1.string else {
                throw NodeError.unableToConvert(input: $1.node, expectation: "\(String.self)", path: [$0])
            }

            newKeyLookup[$0] = value
        }

        keys = newKeyLookup

        guard let key = newKeyLookup[identifier] else {
            throw Abort.custom(status: .internalServerError, message: "\(identifier) key does not exist.")
        }

        return key
    }

    func authenticateUserFor(subject: String, with request: Request, create: Bool) throws -> AuthenticationSubject {
        let type: SessionType = try request.extract()

        switch type {
        case .customer:
            let customer = try getAuthenticationSubject(subject: subject, create: create) as Customer
            try request.auth.authenticate(customer, persist: true)
            return customer

        case .maker:
            let maker = try getAuthenticationSubject(subject: subject, create: create) as Maker
            try request.auth.authenticate(maker, persist: true)
            return maker

        case .anonymous:
            throw Abort.custom(status: .badRequest, message: "Can not sign user up with anonymous session type.")
        }
    }

    func getAuthenticationSubject<T: AuthenticationSubject>(subject: String, request: Request? = nil, create new: Bool = true) throws -> T {
        if let callee = try T.makeQuery().filter("sub_id", subject).first() {
            return callee
        }

        if new {
            guard let request = request else {
                throw AuthError.noRequest
            }

            return try T.init(subject: subject, request: request)
        } else {
            throw AuthenticationError.notAuthenticated
        }
    }
}
