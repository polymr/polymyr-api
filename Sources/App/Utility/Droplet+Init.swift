//
//  Droplet+Init.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/28/16.
//
//

import Vapor
import Sessions
import MySQLProvider
import Fluent
import FluentProvider
import HTTP
import Console
import MySQLProvider
import AuthProvider

extension SessionsMiddleware {
    
    class func createSessionsMiddleware() -> SessionsMiddleware {
        let memory = MemorySessions()
        return SessionsMiddleware(memory)
    }
}

extension Droplet {

    internal static func create() -> Droplet {

        do {
            let drop = try Droplet()

            drop.log.enabled = LogLevel.all

            try drop.addProvider(AuthProvider.Provider.self)
            try drop.addProvider(MySQLProvider.Provider.self)

            drop.preparations += [Product.self,
                                  Maker.self,
                                  CustomerAddress.self,
                                  Customer.self,
                                  CustomerSessionToken.self,
                                  StripeMakerCustomer.self,
                                  MakerAddress.self,
                                  Campaign.self,
                                  Answer.self,
                                  QuestionSection.self,
                                  Question.self,
                                  Order.self,
                                  Pivot<Tag, Product>.self,
                                  MakerPicture.self,
                                  CustomerPicture.self,
                                  ProductPicture.self,
                                  Tag.self] as [Preparation.Type]

            return drop

        } catch {
            fatalError("Failed to start with error \(error)")
        }
    }
}
