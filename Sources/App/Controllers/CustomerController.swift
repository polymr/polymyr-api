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
            
        case .vendor:
            let vendor = try request.vendor()
            throw try Abort.custom(status: .forbidden, message: "Vendor(\(vendor.throwableId()) can not perform \(request.method) on Customer(\(throwableId())).")
            
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
        var customerNode = try customer.makeNode()

        guard let stripe_id = customer.stripe_id else {
            throw Abort.custom(status: .badRequest, message: "User is missing a stripe id.")
        }

        let options = try request.extract() as [FetchType]

        if options.contains(.stripe) {
            // TODO : is card needed here, and update documentation
            if let card = request.query?["card"]?.string {
                let cards = try Stripe.shared.paymentInformation(for: stripe_id)
                customerNode["card"] = try cards.filter { $0.id == card }.first?.makeNode()
            } else {
                let stripeData = try Stripe.shared.customerInformation(for: stripe_id)
                customerNode["stripe"] = try stripeData.makeNode()
            }
        }

        if options.contains(.shipping) {
            let shipping = try customer.shippingAddresses().all()
            customerNode["shipping"] = try shipping.makeNode()
        }

        return try customerNode.makeJSON()
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
