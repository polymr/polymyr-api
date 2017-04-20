//
//  HTTPClient.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/19/17.
//
//

import JSON
import HTTP
import Foundation
import Vapor

public struct StripeHTTPError: AbortError {
    public let status: HTTP.Status
    public let reason: String
    public let metadata: Node?

    init(node: Node, code: Status) {
        self.metadata = node
        self.status = code
        self.reason = "Stripe Error"
    }
}

func createToken(token: String) throws -> [HeaderKey: String] {
    let base64 = token.bytes.base64Encoded
    return try ["Authorization" : "Basic \(base64.string())"]
}

public class HTTPClient {
    
    let baseURLString: String
    
    init(urlString: String) {
        baseURLString = urlString
    }
    
    func get<T: NodeConvertible>(_ resource: String, query: [String : NodeRepresentable] = [:], token: String = Stripe.secret) throws -> T {
        let response = try drop.client.get(baseURLString + resource, query: query, createToken(token: token))
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        try checkForStripeError(in: json, from: resource)
        
        return try T.init(node: json.makeNode(in: emptyContext))
    }
    
    func get_list<T: NodeConvertible>(_ resource: String, query: [String : NodeRepresentable] = [:], token: String = Stripe.secret) throws -> [T] {
        let response = try drop.client.get(baseURLString + resource, query: query, createToken(token: token))
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        try checkForStripeError(in: json, from: resource)
        
        guard let objects = json.node["data"]?.array else {
            throw Abort.custom(status: .internalServerError, message: "Unexpected response formatting. \(json)")
        }
        
        return try objects.map {
            return try T.init(node: $0)
        }
    }
    
    func post<T: NodeConvertible>(_ resource: String, query: [String : NodeRepresentable] = [:], token: String = Stripe.secret) throws -> T {
        let response = try drop.client.post(baseURLString + resource, query: query, createToken(token: token))
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        try checkForStripeError(in: json, from: resource)
        
        return try T.init(node: json.makeNode(in: emptyContext))
    }

    func delete(_ resource: String, query: [String : NodeRepresentable] = [:], token: String = Stripe.secret) throws -> JSON {
        let response = try drop.client.delete(baseURLString + resource, query: query, createToken(token: token))
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        try checkForStripeError(in: json, from: resource)
        
        return json
    }
    
    private func checkForStripeError(in json: JSON, from resource: String) throws {
        if json["error"] != nil {
            throw StripeHTTPError(node: json.node, code: .internalServerError)
        }
    }
}
