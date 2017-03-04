//
//  Droplet+Init.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/28/16.
//
//

import Foundation
import Vapor
import Sessions
import VaporMySQL
import Fluent
import Auth
import Turnstile
import HTTP
import Console

extension SessionsMiddleware {
    
    class func createSessionsMiddleware() -> SessionsMiddleware {
        let memory = MemorySessions()
        return SessionsMiddleware(sessions: memory)
    }
}

extension Droplet {
    
    static var instance: Droplet?
    static var logger: LogProtocol?
    
    internal static func create() -> Droplet {
        
        let drop = Droplet()
        
        Droplet.instance = drop
        Droplet.logger = drop.log.self
        
        do {
            try drop.addProvider(VaporMySQL.Provider.self)
        } catch {
            logger?.fatal("failed to add vapor provider \(error)")
        }
        
        drop.addConfigurable(middleware: SessionsMiddleware.createSessionsMiddleware(), name: "sessions")
        drop.addConfigurable(middleware: UserAuthMiddleware(), name: "userAuth")
        drop.addConfigurable(middleware: VendorAuthMiddleware(), name: "vendorAuth")
        drop.addConfigurable(middleware: LoggingMiddleware(), name: "logger")
        drop.addConfigurable(middleware: CustomAbortMiddleware(), name: "customAbort")
        
        var remainingMiddleare = drop.middleware.filter { !($0 is FileMiddleware) }
        
        if let fileMiddleware = drop.middleware.filter({ $0 is FileMiddleware }).first {
            remainingMiddleare.append(fileMiddleware)
        }
        
        drop.middleware = remainingMiddleare
        
        let preparations: [Preparation.Type] = [Box.self, Review.self, Vendor.self, Category.self, Picture.self, Order.self, Shipping.self, Subscription.self, Pivot<Box, Category>.self, Customer.self, Session.self, FeaturedBox.self, Onboarding.self, BoxPlan.self, VendorCustomer.self, Coupon.self, VendorAddress.self]
        drop.preparations.append(contentsOf: preparations)

        
        return drop
    }
    
    static let userProtect = UserProtectMiddleware()
    static let vendorProtect = VendorProtectMiddleware()
    
    static func protect(_ type: SessionType) -> Middleware {
        switch type {
        case .customer: return userProtect
        case .vendor: return vendorProtect
        case .none: return userProtect
        }
    }
}
