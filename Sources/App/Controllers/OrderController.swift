//
//  OrderController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/4/17.
//
//

import HTTP
import Vapor
import Fluent
import FluentProvider

extension Stripe {
    
    func order(customer: Customer, product: Product, maker: Maker, campaign: Campaign, card: String) throws -> Charge {
        let price = product.fullPrice
        let reward = campaign.amountOff
        let fee = maker.cut
        
        let feePercentage = reward / price + fee

        guard let stripe_id = customer.stripe_id else {
            throw Abort.custom(status: .badRequest, message: "Customer does not have stripe account.")
        }
    
        guard let secret = maker.keys?.secret else {
            throw Abort.custom(status: .badRequest, message: "Missing vendor keys")
        }

        let token = try Stripe.shared.createToken(for: stripe_id, representing: card, on: secret)
        return try Stripe.shared.charge(source: token.id, for: price, withFee: feePercentage, under: secret)
    }
}

final class OrderController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {


        let type: SessionType = try request.extract()

        switch type {
        case .customer:
            return try request.customer().orders().all().makeJSON()
        case .maker:
            var query = try request.maker().orders().makeQuery()

            if let fulfilled = request.query?["fulfilled"]?.bool {
                query = try query.filter("fulfilled", fulfilled)
            }

            return try request.maker().orders().all().makeJSON()
        case .anonymous:
            return try Order.all().makeJSON()
        }
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let order: Order = try request.extractModel(injecting: request.customerInjectable())

        guard let campaign = try order.campaign().first() else {
            throw Abort.custom(status: .badRequest, message: "no campaign")
        }
        
        guard let customer = try order.customer().first() else {
            throw Abort.custom(status: .badRequest, message: "no customer")
        }

        guard let product = try campaign.product().first(), let maker = try campaign.maker().first() else {
            throw Abort.custom(status: .internalServerError, message: "malformed campaign object")
        }

        let charge = try Stripe.shared.order(customer: customer, product: product, maker: maker, campaign: campaign, card: order.card)
        order.charge_id = charge.id

        try order.save()
        return try order.makeResponse()
    }
    
    func delete(_ request: Request, order: Order) throws -> ResponseRepresentable {
        try order.delete()
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, order: Order) throws -> ResponseRepresentable {
        let order: Order = try request.patchModel(order)
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
