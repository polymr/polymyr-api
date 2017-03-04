//
//  HTTPClient.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/19/17.
//
//

import Foundation
import JSON
import class HTTP.Serializer
import class HTTP.Parser
import HTTP
import enum Vapor.Abort
import Transport
import class FormData.Serializer
import class Multipart.Serializer
import struct Multipart.Part
import FormData

func createToken(token: String) -> [HeaderKey: String] {
    let data = token.data(using: .utf8)!.base64EncodedString()
    return ["Authorization" : "Basic \(data)"]
}

public class HTTPClient {
    
    let baseURLString: String
    let client: Client<TCPClientStream, HTTP.Serializer<Request>, HTTP.Parser<Response>>.Type
    
    init(urlString: String) {
        baseURLString = urlString
        client = Client<TCPClientStream, HTTP.Serializer<Request>, HTTP.Parser<Response>>.self
    }
    
    func get<T: NodeConvertible>(_ resource: String, query: [String : CustomStringConvertible] = [:], token: String = Stripe.token) throws -> T {
        let response = try client.get(baseURLString + resource, headers: createToken(token: token), query: query)
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        try checkForStripeError(in: json, from: resource)
        
        return try T.init(node: json.makeNode())
    }
    
    func get<T: NodeConvertible>(_ resource: String, query: [String : CustomStringConvertible] = [:], token: String = Stripe.token) throws -> [T] {
        let response = try client.get(baseURLString + resource, headers: createToken(token: token), query: query)
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        try checkForStripeError(in: json, from: resource)
        
        guard let objects = json.node["data"]?.nodeArray else {
            throw Abort.custom(status: .internalServerError, message: "Unexpected response formatting. \(json)")
        }
        
        return try objects.map {
            return try T.init(node: $0)
        }
    }
    
    func post<T: NodeConvertible>(_ resource: String, query: [String : CustomStringConvertible] = [:], token: String = Stripe.token) throws -> T {
        let response = try client.post(baseURLString + resource, headers: createToken(token: token), query: query)
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        try checkForStripeError(in: json, from: resource)
        
        return try T.init(node: json.makeNode())
    }
    
    func upload<T: NodeConvertible>(_ resource: String, query: [String: CustomStringConvertible] = [:], name: String, bytes: Bytes) throws -> T {
        guard let boundry = "\(UUID().uuidString)-boundary-\(UUID().uuidString)".data(using: .utf8) else {
            throw Abort.custom(status: .internalServerError, message: "Error generating mulitpart form data boundy for upload to Stripe.")
        }
        
        var data: Bytes = []
        
        let multipartSerializer = Multipart.Serializer(boundary: [UInt8](boundry))
        
        multipartSerializer.onSerialize = { bytes in
            data.append(contentsOf: bytes)
        }
        
        let formDataSerializer = FormData.Serializer(multipart: multipartSerializer)
        let fileField = Field(name: name, filename: nil, part: Multipart.Part.init(headers: [:], body: bytes))
        
        try formDataSerializer.serialize(fileField)
        try formDataSerializer.multipart.finish()
        
        let contentType = try FormData.Serializer.generateContentType(boundary: boundry).string()
        let response = try client.post(baseURLString + resource, headers: [.contentType : contentType], body: Body.data(data))
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        try checkForStripeError(in: json, from: resource)
        
        return try T.init(node: json.makeNode())
    }
    
    func delete(_ resource: String, query: [String : CustomStringConvertible] = [:], token: String = Stripe.token) throws -> JSON {
        let response = try client.delete(baseURLString + resource, headers: createToken(token: token), query: query)
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        try checkForStripeError(in: json, from: resource)
        
        return json
    }
    
    private func checkForStripeError(in json: JSON, from resource: String) throws {
        if json.node["error"] != nil {
            throw Abort.custom(status: .internalServerError, message: "Error from Stripe:\(resource) >>> \(json.prettyString)")
        }
    }
}
