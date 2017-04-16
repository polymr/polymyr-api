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
import CTLS
import Crypto

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

public enum HashMethod {
    case sha256
    case sha384
    case sha512
}

extension HashMethod {
    var type: Int32 {
        switch self {
        case .sha256: return NID_sha256
        case .sha384: return NID_sha384
        case .sha512: return NID_sha512
        }
    }
    
    var method: Hash.Method {
        switch self {
        case .sha256: return .sha256
        case .sha384: return .sha384
        case .sha512: return .sha512
        }
    }
}

typealias CRSAKey = UnsafeMutablePointer<RSA>

enum RSAKey {
    case `public`(CRSAKey)
    case `private`(CRSAKey)
    
    public init(_ rawKey: Bytes) throws {
        guard let rsa = rawKey.withUnsafeBufferPointer({ rawKeyPointer -> RSAKey? in
            var base = rawKeyPointer.baseAddress
            let count = rawKey.count
            
            if let cPrivateKey = d2i_RSAPrivateKey(nil, &base, count) {
                return .private(cPrivateKey)
            } else if let cPublicKey = d2i_RSA_PUBKEY(nil, &base, count) {
                return .public(cPublicKey)
            } else {
                return nil
            }
        }) else {
            throw JWTError.createKey
        }
        
        self = rsa
    }
    
    var cKey: CRSAKey {
        switch self {
        case .public(let cKey):
            return cKey
        case .private(let cKey):
            return cKey
        }
    }
}

public final class Certificate_RS256 : Signer {
    
    let key: RSAKey
    let hashMethod = HashMethod.sha256
    
    public var name = "RS256"
    
    init(certificate: String) throws {
        let certificateBytes = certificate.bytes
        
        let cert_bio = BIO_new_mem_buf(certificateBytes, Int32(certificateBytes.count))
        var _cert: UnsafeMutablePointer<X509>?
        PEM_read_bio_X509(cert_bio, &_cert, nil, nil)
        
        guard let cert = _cert else {
            throw Abort.custom(status: .internalServerError, message: "Failed to decode certificate.")
        }
        
        guard let publicKey = X509_get_pubkey(cert) else {
            throw Abort.custom(status: .internalServerError, message: "Failed to decode public key.")
        }
        
        guard let rsa = EVP_PKEY_get1_RSA(publicKey) else {
            throw Abort.custom(status: .internalServerError, message: "Failed to get rsa key.")
        }
        
        self.key = .public(rsa)
    }
    
    public func sign(message: Bytes) throws -> Bytes {
        guard case .private(let cKey) = key else {
            throw JWTError.privateKeyRequired
        }
        
        var siglen: UInt32 = 0
        var sig = Bytes(
            repeating: 0,
            count: Int(RSA_size(cKey))
        )
        
        let digest = try Hash(hashMethod.method, message).hash()
        
        RSA_sign(
            hashMethod.type,
            digest,
            UInt32(digest.count),
            &sig,
            &siglen,
            cKey
        )
        
        return sig
    }
    
    public func verify(signature: Bytes, message: Bytes) throws {
        let digest = try Hash(hashMethod.method, message).hash()
        
        let result = RSA_verify(
            hashMethod.type,
            digest,
            UInt32(digest.count),
            signature,
            UInt32(signature.count),
            key.cKey
        )
        
        guard result == 1 else {
            throw JWTError.signatureVerificationFailed
        }
    }
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
            let certificate = try self.fetchSigningKey(for: jwt.headers.extract("kid") as String)
            let signer = try Certificate_RS256(certificate: certificate)
            
            // TODO : IssuedAtClaim should be in the past
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
                throw AuthenticationError.notAuthenticated
            }

            return try T.init(subject: subject, request: request)
        } else {
            throw AuthenticationError.notAuthenticated
        }
    }
}
