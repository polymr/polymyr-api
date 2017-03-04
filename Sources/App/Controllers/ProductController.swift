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
        return try Product.all().makeNode().makeJSON()
    }
    
    func show(_ request: Request, product: Product) throws -> ResponseRepresentable {
        return product
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let _ = try request.maker()
        
        var product: Product = try request.extractModel(injecting: request.makerInjectable())
        try product.save()
        return product
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
