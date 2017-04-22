//
//  ProductController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
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

enum Sort: String, TypesafeOptionsParameter {
    
    case alpha
    case price
    case new
    case none
    
    static let key = "sort"
    static let values = [Sort.alpha.rawValue, Sort.new.rawValue, Sort.price.rawValue, Sort.none.rawValue]
    static let defaultValue: Sort? = Sort.none
    
    var field: String {
        switch self {
        case .alpha:
            return "name"
        case .price:
            return "fullPrice"
        case .new:
            // TODO : hacky
            return "id"
        case .none:
            return ""
        }
    }
    
    func modify<T : Entity>(_ query: Query<T>) throws -> Query<T> {
        if self == .none {
            return query
        }
        
        return try query.sort(field, .ascending)
    }
}

struct Expander<T: Model & NodeConvertible>: QueryInitializable {
    
    static var key: String {
        return "expand"
    }
    
    let expandKeyPaths: [String]
    
    init(node: Node) throws {
        expandKeyPaths = node.string?.components(separatedBy: ",") ?? []
    }
    
    func expand(for models: [T], mappings: @escaping (String, [T], [Node]) throws -> [NodeRepresentable]) throws -> Node {
        let ids = models.map { $0.id!.makeNode(in: jsonContext) }
        
        let relationships = try expandKeyPaths.map { relation in
            return try (relation, mappings(relation, models, ids))
        }
        
        var result: [Node] = []
        
        for owner in models {
            try result.append(.object([T.name : owner.makeNode(in: jsonContext)]))
        }
        
        for (key, relations) in relationships {
            for (index, relation) in relations.enumerated() {
                try result[index].set(key, relation.makeNode(in: jsonContext))
            }
        }
        
        return Node.array(result).makeNode(in: jsonContext)
    }
    
    func expand(for model: T, mappings: @escaping (String, [T], [Node]) throws -> [NodeRepresentable]) throws -> Node {
        return try expand(for: [model] as [T], mappings: mappings).array!.first!
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
        
        let sort = try request.extract() as Sort
        
        let products = try { () -> [Product] in
            if let maker = request.query?["maker"]?.bool, maker {
                let maker = try request.maker()
                return try sort.modify(maker.products().makeQuery()).all()
            }
            
            return try sort.modify(Product.makeQuery()).all()
        }()
        
        if products.count == 0 {
            return try Node.array([]).makeResponse()
        }
        
        if let expander: Expander<Product> = try request.extract() {
            return try expander.expand(for: products) { (key, products, identifiers) -> [NodeRepresentable] in
                switch key {
                case "campaign":
                    let campaigns = try Campaign.makeQuery().filter(.subset(Product.foreignIdKey, .in, identifiers)).all()
                    
                    return try identifiers.map { id in
                        try campaigns.filter { try $0.product_id == id.converted(in: emptyContext) }
                    }
                    
                case "tags":
                    return try products.map {
                        try $0.tags().all().makeNode(in: jsonContext)
                    }
                case "maker":
                    let makerIds = products.map { $0.maker_id.makeNode(in: jsonContext) }
                    let makers = try Maker.makeQuery().filter(.subset(Maker.idKey, .in, makerIds)).all()
                    
                    return try makerIds.map { id in
                        try makers.filter { try $0.id.makeNode(in: emptyContext) == id }.first
                    }
                case "pictures":
                    let pictures = try ProductPicture.makeQuery().filter(.subset(Product.foreignIdKey, .in, identifiers)).all()
                    
                    return try identifiers.map { id in
                        try pictures.filter { try $0.product_id == id.converted(in: emptyContext) }
                    }
                default:
                    throw Abort.custom(status: .badRequest, message: "Could not find expansion for \(key) on \(type(of: self)).")
                }
            }.makeResponse()
        }
        
        return try products.makeJSON()
    }
    
    func show(_ request: Request, product: Product) throws -> ResponseRepresentable {
        
        if let expander: Expander<Product> = try request.extract() {
            return try expander.expand(for: product, mappings: { (key, products, identifiers) -> [NodeRepresentable] in
                switch key {
                case "campaign":
                    return try products[0].campaign().limit(1).all()
                case "tags":
                    return try [products[0].tags().all().makeNode(in: jsonContext)]
                case "maker":
                    return try products[0].maker().limit(1).all()
                case "pictures":
                    return try [products[0].pictures().all().makeNode(in: jsonContext)]
                default:
                    fatalError("Could not find expansion for \(key) on ProductController.")
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
        
        if var campaignNode: Node = try? node.extract("campaign") {
            campaignNode = try campaignNode.add(objects: ["maker_id" : request.maker().throwableId(), "product_id" : product.throwableId()])
            let campaign: Campaign = try Campaign(node: campaignNode, in: emptyContext)
            try campaign.save()
            
            result["campaign"] = try campaign.makeNode(in: emptyContext)
        }

        if let pictureNode: [Node] = try? node.extract("pictures") {

            let pictures = try pictureNode.map { (object: Node) -> ProductPicture in
                let context = ParentContext(parent_id: product_id)
                let picture: ProductPicture = try ProductPicture(node: Node(object.permit(ProductPicture.permitted).wrapped, in: context))
                try picture.save()
                return picture
            }

            result["pictures"] = try pictures.makeNode(in: emptyContext)
        }
        
        if let tags: [Int] = try? node.extract("tags") {
        
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
