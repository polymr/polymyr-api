//
//  ProductController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Foundation
import Vapor
import enum HTTP.Method
import HTTP
import Fluent
import Sanitized

typealias Pair = (Hashable, Any)

func merge<K: Hashable, V>(keys: [K], with values: [V]) -> [K: V] {
    var dictionary: [K: V] = [:]
    
    zip(keys, values).forEach { key, value in
        dictionary[key] = value
    }
    
    return dictionary
}

struct Expander: QueryInitializable {
    
    static var key: String = "expand"
    
    let expandKeyPaths: [String]
    
    init(node: Node, in context: Context) throws {
        expandKeyPaths = node.string?.components(separatedBy: ",") ?? []
    }
    
    func expand<T: Model>(for models: [T], owner key: String, mappings: @escaping (String, T) throws -> (NodeRepresentable?)) throws -> [Node] {
        return try models.map { (model: T) -> Node in
            var valueMappings = try expandKeyPaths.map { relation in
                return try mappings(relation, model)?.makeNode() ?? Node.null
            }
            
            var keyPaths = expandKeyPaths
            
            keyPaths.append(key)
            try valueMappings.append(model.makeNode())
            
            return try merge(keys: keyPaths, with: valueMappings).makeNode()
        }
    }
}

extension Product {
    
    func shouldAllow(request: Request) throws {
        guard let maker = try? request.maker() else {
            throw try Abort.custom(status: .forbidden, message: "Method \(request.method) is not allowed on resource Product(\(throwableId())) by this user. Must be logged in as Maker(\(maker_id?.int ?? 0)).")
        }
        
        guard try maker.throwableId() == maker_id?.int else {
            throw try Abort.custom(status: .forbidden, message: "This Maker(\(maker.throwableId()) does not have access to resource Product(\(throwableId()). Must be logged in as Maker(\(maker_id?.int ?? 0).")
        }
    }
}

final class ProductController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        let products = try Product.all()
        
        if let expander: Expander = try request.extract() {
            return try Node.array(expander.expand(for: products, owner: "products", mappings: { (key, product) -> (NodeRepresentable?) in
                switch key {
                case "campaign":
                    return try product.campaign().first()
                case "tags":
                    return try product.tags().all().makeNode()
                default:
                    Droplet.logger?.warning("Could not find expansion for \(key) on ProductController.")
                    return nil
                }
            })).makeJSON()
        }
        
        if let shouldIncludeCampaigns = request.query?["campaign"]?.bool, shouldIncludeCampaigns {
            let result = try products.map { (product: Product) -> Node in
                let campaign = try product.campaign().first()
                return Node.object(["product" : try product.makeNode(), "campaign" : try campaign?.makeNode() ?? Node.null])
            }
            
            return try result.makeJSON()
        }
        
        return try products.makeJSON()
    }
    
    func show(_ request: Request, product: Product) throws -> ResponseRepresentable {
        return product
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let _ = try request.maker()
        var result: [String : Node] = [:]
        
        var product: Product = try request.extractModel(injecting: request.makerInjectable())
        try product.save()
        result["product"] = try product.makeNode()
        
        if var campaignNode = request.json?.node["campaign"] {
            campaignNode = try campaignNode.add(objects: ["maker_id" : request.maker().throwableId(), "product_id" : product.throwableId()])
            var campaign: Campaign = try Campaign(node: campaignNode, in: EmptyNode)
            try campaign.save()
            
            result["campaign"] = try campaign.makeNode()
        }
        
        if let node = request.json?.node, let tags: [Int] = try node.extract("tags") {
        
            let tags = try tags.map { (id: Int) -> Tag? in
                guard let tag = try Tag.find(id) else {
                    return nil
                }
                
                var pivot = Pivot<Tag, Product>(tag, product)
                try pivot.save()
                
                return tag
            }.flatMap { $0 }
            
            result["tags"] = try tags.makeNode()
        }
        
        return try result.makeNode().makeJSON()
    }
    
    func delete(_ request: Request, product: Product) throws -> ResponseRepresentable {
        try product.shouldAllow(request: request)
        
        try product.delete()
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, product: Product) throws -> ResponseRepresentable {
        try product.shouldAllow(request: request)
        
        var product: Product = try request.patchModel(product)
        try product.save()
        return try Response(status: .ok, json: product.makeJSON())
    }
    
    func makeResource() -> Resource<Product> {
        return Resource(
            index: index,
            store: create,
            show: show,
            modify: modify,
            destroy: delete
        )
    }
}
