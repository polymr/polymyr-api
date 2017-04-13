//
//  ProductController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import enum HTTP.Method
import HTTP
import Fluent
import FluentProvider

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
    
    init(node: Node) throws {
        expandKeyPaths = node.string?.components(separatedBy: ",") ?? []
    }
    
    func expand<T: Model>(for models: [T], owner key: String, mappings: @escaping (String, T) throws -> (NodeRepresentable?)) throws -> [Node] where T: NodeConvertible {
        return try models.map { (model: T) -> Node in
            var valueMappings = try expandKeyPaths.map { relation in
                return try mappings(relation, model)?.makeNode(in: emptyContext) ?? Node.null
            }
            
            var keyPaths = expandKeyPaths
            
            keyPaths.append(key)
            try valueMappings.append(model.makeNode(in: emptyContext))
            
            return try merge(keys: keyPaths, with: valueMappings).makeNode(in: emptyContext)
        }
    }
    
    func expand<T: Model>(for model: T, owner key: String, mappings: @escaping (String, T) throws -> (NodeRepresentable?)) throws -> Node where T: NodeConvertible {
        var valueMappings = try expandKeyPaths.map { relation in
            return try mappings(relation, model)?.makeNode(in: emptyContext) ?? Node.null
        }
        
        var keyPaths = expandKeyPaths
        
        keyPaths.append(key)
        try valueMappings.append(model.makeNode(in: emptyContext))
        
        return try merge(keys: keyPaths, with: valueMappings).makeNode(in: emptyContext)
    }
}

extension Product {
    
    func shouldAllow(request: Request) throws {
        guard let maker = try? request.maker() else {
            throw try Abort.custom(status: .forbidden, message: "Method \(request.method) is not allowed on resource Product(\(throwableId())) by this user. Must be logged in as Maker(\(maker_id.int ?? 0)).")
        }
        
        guard try maker.throwableId() == maker_id.int else {
            throw try Abort.custom(status: .forbidden, message: "This Maker(\(maker.throwableId()) does not have access to resource Product(\(throwableId()). Must be logged in as Maker(\(maker_id.int ?? 0).")
        }
    }
}

public struct ParentContext: Context {

    public let parent_id: Identifier
}

final class ProductController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        
        let products = try { () -> [Product] in
            if let maker = request.query?["maker"]?.bool, maker {
                let maker = try request.maker()
                return try maker.products().all()
            }
            
            return try Product.all()
        }()
        
        if let expander: Expander = try request.extract() {
            return try expander.expand(for: products, owner: "product", mappings: { (key, product) -> (NodeRepresentable?) in
                switch key {
                case "campaign":
                    return try product.campaign().first()
                case "tags":
                    return try product.tags().all().makeNode(in: jsonContext)
                case "maker":
                    return try product.maker().first()
                case "pictures":
                    return try product.pictures().all().makeNode(in: jsonContext)
                default:
                    drop.log.warning("Could not find expansion for \(key) on ProductController.")
                    return nil
                }
            }).makeResponse()
        }
        
        return try products.makeJSON()
    }
    
    func show(_ request: Request, product: Product) throws -> ResponseRepresentable {
        
        if let expander: Expander = try request.extract() {
            return try expander.expand(for: product, owner: "product", mappings: { (key, product) -> (NodeRepresentable?) in
                switch key {
                case "campaign":
                    return try product.campaign().first()
                case "tags":
                    return try product.tags().all().makeNode(in: jsonContext)
                case "maker":
                    return try product.maker().first()
                case "pictures":
                    return try product.pictures().all().makeNode(in: jsonContext)
                default:
                    drop.log.warning("Could not find expansion for \(key) on ProductController.")
                    return nil
                }
            }).makeResponse()
        }
        
        return try product.makeResponse()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let _ = try request.maker()
        var result: [String : Node] = [:]
    
        let product: Product = try request.extractModel(injecting: request.makerInjectable())
        try product.save()

        guard let product_id = product.id else {
            throw Abort.custom(status: .internalServerError, message: "Failed to save product.")
        }

        result["product"] = try product.makeNode(in: emptyContext)

        guard let node = request.json?.node else {
            return try JSON(result.makeNode(in: jsonContext))
        }
        
        if var campaignNode: Node = try node.extract("campaign") {
            campaignNode = try campaignNode.add(objects: ["maker_id" : request.maker().throwableId(), "product_id" : product.throwableId()])
            let campaign: Campaign = try Campaign(node: campaignNode, in: emptyContext)
            try campaign.save()
            
            result["campaign"] = try campaign.makeNode(in: emptyContext)
        }

        if let pictureNode: [Node] = try node.extract("pictures") {

            let pictures = try pictureNode.map { (object: Node) -> ProductPicture in
                let context = ParentContext(parent_id: product_id)
                let picture: ProductPicture = try ProductPicture(node: Node(object.permit(ProductPicture.permitted).wrapped, in: context))
                try picture.save()
                return picture
            }

            result["pictures"] = try pictures.makeNode(in: emptyContext)
        }
        
        if let node = request.json?.node, let tags: [Int] = try node.extract("tags") {
        
            let tags = try tags.map { (id: Int) -> Tag? in
                guard let tag = try Tag.find(id) else {
                    return nil
                }
                
                let pivot = try Pivot<Tag, Product>(tag, product)
                try pivot.save()
                
                return tag
            }.flatMap { $0 }
            
            result["tags"] = try tags.makeNode(in: emptyContext)
        }
        
        return try JSON(result.makeNode(in: jsonContext))
    }
    
    func delete(_ request: Request, product: Product) throws -> ResponseRepresentable {
        try product.shouldAllow(request: request)
        
        try product.delete()
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, product: Product) throws -> ResponseRepresentable {
        try product.shouldAllow(request: request)
        
        let product: Product = try request.patchModel(product)
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
