//
//  Model+Convenience.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 4/10/17.
//
//

import HTTP
import Vapor
import Fluent
import FluentProvider

extension NodeConvertible {
    
    public func makeResponse() throws -> Response {
        return try Response(status: .ok, json: JSON(makeNode(in: jsonContext)))
    }
}

extension Model {
    
    func throwableId() throws -> Int {
        guard let id = id else {
            throw Abort.custom(status: .internalServerError, message: "Bad internal state. \(type(of: self).entity) does not have database id when it was requested.")
        }
        
        guard let customerIdInt = id.int else {
            throw Abort.custom(status: .internalServerError, message: "Bad internal state. \(type(of: self).entity) has database id but it was of type \(id.wrapped.type) while we expected number.int")
        }
        
        return customerIdInt
    }
}
