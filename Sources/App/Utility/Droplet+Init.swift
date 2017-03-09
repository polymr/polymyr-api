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
        drop.addConfigurable(middleware: CustomerAuthMiddleware(), name: "customerAuth")
        drop.addConfigurable(middleware: MakerAuthMiddleware(), name: "makerAuth")
        drop.addConfigurable(middleware: LoggingMiddleware(), name: "logger")
        drop.addConfigurable(middleware: CustomAbortMiddleware(), name: "customAbort")
        
        var remainingMiddleare = drop.middleware.filter { !($0 is FileMiddleware) }
        
        if let fileMiddleware = drop.middleware.filter({ $0 is FileMiddleware }).first {
            remainingMiddleare.append(fileMiddleware)
        }
        
        drop.middleware = remainingMiddleare
        
        let preparations: [Preparation.Type] = [Product.self, Maker.self, CustomerAddress.self, Customer.self, Session.self, StripeMakerCustomer.self, MakerAddress.self, Campaign.self, Answer.self, QuestionSection.self, Question.self, Order.self, Pivot<Tag, Product>.self, MakerPicture.self, CustomerPicture.self, ProductPicture.self]
        drop.preparations.append(contentsOf: preparations)
        
        return drop
    }
    
    static let userProtect = CustomerProtectMiddleware()
    static let makerProtect = MakerProtectMiddleware()
    
    static func protect(_ type: SessionType) -> Middleware {
        switch type {
        case .customer: return userProtect
        case .maker: return makerProtect
        case .none: return userProtect
        }
    }
}
