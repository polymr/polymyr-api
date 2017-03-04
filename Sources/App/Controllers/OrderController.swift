//
//  OrderController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/4/17.
//
//

import Foundation
import HTTP
import Vapor
import Fluent

final class OrderController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        return try Order.all().makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var order: Order = try request.extractModel(injecting: request.customerInjectable())
        try order.save()
        return order
    }
    
    func delete(_ request: Request, order: Order) throws -> ResponseRepresentable {
        try order.delete()
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, order: Order) throws -> ResponseRepresentable {
        var order: Order = try request.patchModel(order)
        try order.save()
        return try Response(status: .ok, json: order.makeJSON())
    }
    
    func makeResource() -> Resource<Order> {
        return Resource(
            index: index,
            store: create,
            modify: modify,
            destroy: delete
        )
    }
}
