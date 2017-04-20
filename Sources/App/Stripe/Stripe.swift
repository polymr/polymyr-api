//
//  Stripe.swift
//  Stripe
//
//  Created by Hakon Hanesand on 12/23/16.
//
//

import JSON
import HTTP
import Transport
import Vapor
import Foundation

fileprivate func merge(query: [String: NodeRepresentable?], with metadata: [String: NodeRepresentable]) -> [String: NodeRepresentable] {
    let arguments = metadata.map { ("metadata[\($0)]", $1) }
    var result: [String: NodeRepresentable] = [:]
    
    arguments.forEach {
        result[$0] = $1
    }
    
    query.forEach {
        if ($1 != nil) {
            result[$0] = $1
        }
    }
    
    return result
}

public final class Stripe {

    public static let shared = Stripe()

    static var token = "pk_test_lGLXGH2jjEx7KFtPmAYz39VA"
    static var secret = "sk_test_WceGrEBqnYpjCYF6exFBXvnf"
    
    fileprivate let base = HTTPClient(urlString: "https://api.stripe.com/v1/")
    fileprivate let uploads = HTTPClient(urlString: "https://uploads.stripe.com/v1/")

    public func createToken() throws -> Token {
        return try base.post("tokens", query: ["card[number]" : 4242424242424242, "card[exp_month]" : 12, "card[exp_year]" : 2017, "card[cvc]" : 123])
    }
    
    public func createToken(for customer: String, representing card: String, on account: String = token) throws -> Token {
        return try base.post("tokens", query: ["customer" : customer, "card" : card], token: account)
    }

    public func createNormalAccount(email: String, source: String, local_id: Int?, on account: String = secret) throws -> StripeCustomer {
        let defaultQuery = ["source" : source]
        let query = local_id.flatMap { merge(query: defaultQuery, with: ["id" : "\($0)"]) } ?? defaultQuery

        return try base.post("customers", query: query, token: account)
    }

    public func createManagedAccount(email: String, local_id: Int?) throws -> StripeAccount {
        let defaultQuery: [String: NodeRepresentable] = ["managed" : true, "country" : "US", "email" : email, "legal_entity[type]" : "company"]
        let query = local_id.flatMap { merge(query: defaultQuery, with: ["id" : "\($0)"]) } ?? defaultQuery
        return try base.post("accounts", query: query, token: Stripe.secret)
    }

    public func associate(source: String, withStripe id: String, under secretKey: String = Stripe.secret) throws -> Card {
        return try base.post("customers/\(id)/sources", query: ["source" : source], token: secretKey)
    }

    public func createPlan(with price: Double, name: String, interval: Interval, on account: String = Stripe.token) throws -> Plan {
        let parameters = ["id" : "\(UUID().uuidString)", "amount" : "\(Int(price * 100))", "currency" : "usd", "interval" : interval.rawValue, "name" : name]
        return try base.post("plans", query: parameters, token: account)
    }
    
    public func update(customer id: String, parameters: [String : String]) throws-> StripeCustomer {
        return try base.post("customer/\(id)", query: parameters)
    }

    public func subscribe(user userId: String, to planId: String, with frequency: Interval = .month, oneTime: Bool, cut: Double, coupon: String? = nil, metadata: [String : NodeRepresentable], under publishableKey: String) throws -> StripeSubscription {
        let subscription: StripeSubscription = try base.post("subscriptions", query: merge(query: ["customer" : userId, "plan" : planId, "application_fee_percent" : cut, "coupon" : coupon], with: metadata), token: publishableKey)

        if oneTime {
            let json = try base.delete("/subscriptions/\(subscription.id)", query: ["at_period_end" : true])

            guard json["cancel_at_period_end"]?.bool == true else {
                throw Abort.custom(status: .internalServerError, message: json.makeNode(in: emptyContext).object?.description ?? "Fuck.")
            }
        }

        return subscription
    }
    
    public func charge(source: String, for price: Double, withFee percent: Double, under account: String = Stripe.token) throws -> Charge {
        return try base.post("charges", query: ["amount" : Int(price * 100), "currency" : "USD", "application_fee" : Int(price * percent * 100), "source" : source], token: account)
    }
    
    public func createCoupon(code: String) throws -> StripeCoupon {
        return try base.post("coupons", query: ["duration": Duration.once.rawValue, "id" : code, "percent_off" : 5, "max_redemptions" : 1])
    }

    public func paymentInformation(for customer: String, under account: String = Stripe.secret) throws -> [Card] {
        return try base.get_list("customers/\(customer)/sources", query: ["object" : "card"], token: account)
    }

    public func customerInformation(for customer: String) throws -> StripeCustomer {
        return try base.get("customers/\(customer)")
    }
    
    public func makerInformation(for maker: String) throws -> StripeAccount {
        return try base.get("accounts/\(maker)")
    }
    
    public func transfers(for secretKey: String) throws -> [Transfer] {
        return try base.get_list("transfers", token: secretKey)
    }

    public func delete(payment: String, from customer: String) throws -> JSON {
        return try base.delete("customers/\(customer)/sources/\(payment)")
    }

    public func disputes() throws -> [Dispute] {
        return try base.get_list("disputes")
    }

    public func verificationRequiremnts(for country: CountryCode) throws -> Country {
        return try base.get("country_specs/\(country.rawValue.uppercased())")
    }

    public func acceptedTermsOfService(for user: String, ip: String) throws -> StripeAccount {
        return try base.post("accounts/\(user)", query: ["tos_acceptance[date]" : "\(Int(Date().timeIntervalSince1970))", "tos_acceptance[ip]" : ip])
    }

    public func updateInvoiceMetadata(for id: Int, invoice_id: String) throws -> Invoice {
        return try base.post("invoices/\(invoice_id)", query: ["metadata[orders]" : "\(id)"])
    }
    
    public func updateAccount(id: String, parameters: [String : String]) throws -> StripeAccount {
        return try base.post("accounts/\(id)", query: parameters)
    }
}
