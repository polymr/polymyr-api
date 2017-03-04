//
//  Webhooks.swift
//  Stripe
//
//  Created by Hakon Hanesand on 1/2/17.
//
//

import Foundation
import HTTP
import Routing
import Vapor



public final class StripeWebhookManager: RouteCollection {

    public static let shared = StripeWebhookManager()

    public typealias Wrapped = HTTP.Responder

    fileprivate var webhookHandlers: [EventResource : [EventAction : (Event) throws -> (Response)]] = [:]

    public func registerHandler(forResource resource: EventResource, action: EventAction, handler: @escaping (Event) throws -> Response) {

        var resourceHanderGroup = webhookHandlers[resource] ?? [:]
        resourceHanderGroup[action] = handler
        webhookHandlers[resource] = resourceHanderGroup
    }

    public func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {

        builder.grouped("stripe").group("webhook") { webhook in

            webhook.post() { request in
                guard let node = request.json?.node else {
                    throw Abort.custom(status: .badRequest, message: "Could not parse JSON into node.")
                }
                
                let event = try Event(node: node)

                guard let handler = self.webhookHandlers[event.resource]?[event.action] else {
                    return Response(status: .notImplemented)
                }

                return try handler(event)
            }
        }
    }
}
