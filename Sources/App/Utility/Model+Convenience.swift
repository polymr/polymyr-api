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
