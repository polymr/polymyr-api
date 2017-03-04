//
//  Request+Convenience.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/22/17.
//
//

import Foundation
import HTTP
import Vapor

extension Request {
    
    func customerInjectable(key: String = "customer_id") throws -> Node {
        let customer = try self.customer()
        
        guard let id = customer.id?.int else {
            throw Abort.custom(status: .internalServerError, message: "Logged in user does not have id.")
        }
        
        return .object([key : .number(.int(id))])
    }
    
    func vendorInjectable(key: String = "vendor_id") throws -> Node {
        let vendor = try self.vendor()
        
        guard let id = vendor.id?.int else {
            throw Abort.custom(status: .internalServerError, message: "Logged in vendor does not have id.")
        }
        
        return .object([key : .number(.int(id))])
    }
}
