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

    static let repositoryName = "tapcrate-fluent-cache"

    public init(config: Config) throws { }

    func boot(_ config: Config) throws {
        let cache = try config.resolveCache()
        config.addConfigurable(middleware: { _ in SessionsMiddleware(CacheSessions(cache)) }, name: "fluent-sessions")
    }

    func boot(_ droplet: Droplet) throws { }

    public func beforeRun(_ drop: Droplet) {

    }
}

extension Droplet {

    internal static func create() -> Droplet {

        do {
            let config = try Config()

            try config.addProvider(AuthProvider.Provider.self)
            try config.addProvider(MySQLProvider.Provider.self)

            config.addConfigurable(cache: MySQLCache.init, name: "mysql-cache")

            try config.addProvider(FluentCacheProvider.self)

            config.preparations += [
                MakerAddress.self,
                Maker.self,
                MakerPicture.self,
                
                Customer.self,
                CustomerAddress.self,
                CustomerPicture.self,
                StripeMakerCustomer.self,
                
                Product.self,
                ProductPicture.self,
                Tag.self,
                Pivot<Tag, Product>.self,
                
                Campaign.self,
                Order.self,

                QuestionSection.self,
                Question.self,
                Answer.self,
                
                MySQLCache.MySQLCacheEntity.self
            ] as [Preparation.Type]

            let drop = try Droplet(config)

            drop.database?.log = { query in
                print("query : \(query)")
            }

            return drop

        } catch {
            fatalError("Failed to start with error \(error)")
        }
    }
}
