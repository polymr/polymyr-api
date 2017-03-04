//
//  Message+CusomJSONParsing.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/21/16.
//
//

import Foundation
import HTTP
import JSON
import Vapor

extension Message {
    
    func json() throws -> JSON {
        if let existing = storage["json"] as? JSON {
            return existing
        }
        
        guard let type = headers["Content-Type"] else {
            throw Abort.custom(status: .badRequest, message: "Missing Content-Type header.")
        }
        
        guard type.contains("application/json") else {
            throw Abort.custom(status: .badRequest, message: "Missing application/json from Content-Type header.")
        }
        
        guard case let .data(body) = body else {
            throw Abort.custom(status: .badRequest, message: "Incorrect encoding of body contents.")
        }
        
        var json: JSON!
        
        do {
            json = try JSON(bytes: body)
        } catch {
            throw Abort.custom(status: .badRequest, message: "Error parsing JSON in body. Parsing error : \(error)")
        }
        
        storage["json"] = json
        return json
    }
}
