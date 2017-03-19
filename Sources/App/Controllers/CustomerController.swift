//
//  UserController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/12/16.
//
//

import Foundation
import Vapor
import HTTP


enum FetchType: String, TypesafeOptionsParameter {

    case stripe
    case shipping

    static let key = "type"
    static let values = [FetchType.stripe.rawValue, FetchType.shipping.rawValue]

    static var defaultValue: FetchType? = nil
}

extension Customer {
    
    func shouldAllow(request: Request) throws {
        switch request.sessionType {
        case .none:
            throw try Abort.custom(status: .forbidden, message: "Must authenticate as Customer(\(throwableId()) to perform \(request.method) on it.")
            
        case .maker:
            let maker = try request.maker()
            throw try Abort.custom(status: .forbidden, message: "Maker(\(maker.throwableId()) can not perform \(request.method) on Customer(\(throwableId())).")
            
        case .customer:
            let customer = try request.customer()
            
            guard try customer.throwableId() == throwableId() else {
                throw try Abort.custom(status: .forbidden, message: "Customer(\(customer.throwableId()) can not perform \(request.method) on Customer(\(throwableId()).")
            }
        }
    }
}

final class CustomerController {

    func detail(_ request: Request) throws -> ResponseRepresentable {
        let customer = try request.customer()
        
        if let expander: Expander = try request.extract() {
            return try expander.expand(for: customer, owner: "customer", mappings: { (key, product) -> (NodeRepresentable?) in
                switch key {
                case "cards":
                    guard let stripe_id = customer.stripe_id else {
                        throw Abort.custom(status: .badRequest, message: "No stripe id")
                    }
                    
                    return try Stripe.shared.paymentInformation(for: stripe_id).makeNode()
                    
                case "shipping":
                    return try customer.shippingAddresses().all().makeNode()
                    
                default:
                    Droplet.logger?.warning("Could not find expansion for \(key) on ProductController.")
                    return nil
                }
            }).makeJSON()
        }
    
        return try customer.makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var customer: Customer = try request.extractModel()
        try customer.save()
        return customer
    }
    
    func modify(_ request: Request, customer: Customer) throws -> ResponseRepresentable {
        try customer.shouldAllow(request: request)
        
        var customer: Customer = try request.patchModel(customer)
        try customer.save()
        return try Response(status: .ok, json: customer.makeJSON())
    }
}

extension CustomerController: ResourceRepresentable {

    func makeResource() -> Resource<Customer> {
        return Resource(
            index: detail,
            store: create,
            modify: modify
        )
    }
}
