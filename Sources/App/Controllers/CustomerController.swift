//
//  UserController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/12/16.
//
//

import Vapor
import HTTP
import AuthProvider

enum FetchType: String, TypesafeOptionsParameter {

    case stripe
    case shipping

    static let key = "type"
    static let values = [FetchType.stripe.rawValue, FetchType.shipping.rawValue]

    static var defaultValue: FetchType? = nil
}

extension Request {

    func customer() throws -> Customer {
        return try auth.assertAuthenticated(Customer.self)
    }

    func maker() throws -> Maker {
        return try auth.assertAuthenticated(Maker.self)
    }
}

extension Customer {
    
    func shouldAllow(request: Request) throws {
        guard try self.throwableId() == request.customer().throwableId() else {
            throw AuthenticationError.notAuthenticated
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
                    
                    return try Stripe.shared.paymentInformation(for: stripe_id).makeNode(in: jsonContext)
                    
                case "shipping":
                    return try customer.shippingAddresses().all().makeNode(in: jsonContext)
                    
                default:
                    drop.log.warning("Could not find expansion for \(key) on ProductController.")
                    return nil
                }
            }).makeResponse()
        }
    
        return try customer.makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let customer: Customer = try request.extractModel()
        
        if try Customer.makeQuery().filter("email", customer.email).count() > 0 {
            throw Abort.custom(status: .badRequest, message: "Username is taken.")
        }
        
        try customer.save()
        
        request.auth.authenticate(customer)
        return try customer.makeResponse()
    }
    
    func modify(_ request: Request, customer: Customer) throws -> ResponseRepresentable {
        try customer.shouldAllow(request: request)
        
        let customer: Customer = try request.patchModel(customer)
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
