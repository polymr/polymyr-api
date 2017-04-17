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
import Sessions

final class FluentCacheProvider: Vapor.Provider {

    public init(config: Config) throws { }

    public func boot(_ drop: Droplet) throws {

    }

    public func beforeRun(_ drop: Droplet) {
        if let database = drop.database {
            drop.addConfigurable(cache: MySQLCache(database), name: "mysql-cache")
            drop.addConfigurable(middleware: SessionsMiddleware(CacheSessions(drop.cache)), name: "fluent-sessions")
        }
    }
}

extension Droplet {

    internal static func create() -> Droplet {

        do {
            let environment = Environment(id: "debugging")
            let drop = try Droplet(environment: environment)

            try drop.addProvider(AuthProvider.Provider.self)
            try drop.addProvider(MySQLProvider.Provider.self)
            try drop.addProvider(FluentCacheProvider.self)
            
            drop.database?.log = { query in
                print("query : \(query)")
            }

            drop.preparations += [Product.self,
                                  Maker.self,
                                  CustomerAddress.self,
                                  Customer.self,
                                  StripeMakerCustomer.self,
                                  MakerAddress.self,
                                  Campaign.self,
                                  Answer.self,
                                  QuestionSection.self,
                                  Question.self,
                                  Order.self,
                                  Tag.self,
                                  Pivot<Tag, Product>.self,
                                  MakerPicture.self,
                                  CustomerPicture.self,
                                  ProductPicture.self,
                                  MySQLCache.MySQLCacheEntity.self] as [Preparation.Type]

            return drop

        } catch {
            fatalError("Failed to start with error \(error)")
        }
    }
}
