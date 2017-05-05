//
//  CustomerShippingController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/4/17.
//
//

import Vapor
import HTTP

extension CustomerAddress {
    
    func shouldAllow(request: Request) throws {
        guard let customer = try? request.customer() else {
            throw try Abort.custom(status: .forbidden, message: "Method \(request.method) is not allowed on resource CustomerShipping(\(throwableId())) by this user. Must be logged in as Customer(\(customer_id.int ?? 0)).")
        }
        
        guard customer.id?.int == customer_id.int else {
            throw try Abort.custom(status: .forbidden, message: "This Customer(\(customer.throwableId())) does not have access to resource CustomerShipping(\(throwableId()). Must be logged in as Customer(\(customer_id.int ?? 0).")
        }
    }
}

final class CustomerAddressController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        let customer = try request.customer()
        return try customer.shippingAddresses().all().makeResponse()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let _ = try request.customer()
        
        let address: CustomerAddress = try request.extractModel(injecting: request.customerInjectable())
        try address.save()
        return try address.makeResponse()
    }
    
    func delete(_ request: Request, address: CustomerAddress) throws -> ResponseRepresentable {
        try address.shouldAllow(request: request)
        try address.delete()
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, address: CustomerAddress) throws -> ResponseRepresentable {
        try address.shouldAllow(request: request)
        let updated: CustomerAddress = try request.patchModel(address)
        try updated.save()
        return try updated.makeResponse()
    }
    
    func makeResource() -> Resource<CustomerAddress> {
        return Resource(
            index: index,
            store: create,
            modify: modify,
            destroy: delete
        )
    }
}
