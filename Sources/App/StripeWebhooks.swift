//
//  StripeWebhooks.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/29/17.
//
//

import Foundation
import HTTP
import Routing
import Vapor

func extractFrom<T: Model>(metadata: Node) throws -> T? {
    return try metadata[T.entity]?.string.flatMap { try T(from: $0) }
}

class StripeWebhooks {

    static let triggerStrings = ["legal_entity.verification.document",
                                 "legal_entity.additional_owners.0.verification.document",
                                 "legal_entity.additional_owners.1.verification.document",
                                 "legal_entity.additional_owners.2.verification.document",
                                 "legal_entity.additional_owners.3.verification.document"]

    required init() {

        StripeWebhookManager.shared.registerHandler(forResource: .account, action: .updated) { (event) -> Response in
            guard let account = event.data.object as? StripeAccount else {
                throw Abort.custom(status: .internalServerError, message: "Failed to parse the account from the account.updated event.")
            }

            guard let id = account.metadata["id"], let vendor = try Maker.find(id) else {
                Droplet.logger?.error("Stripe account \(account.id) is missing a connected vendor in its metadata.")
                throw Abort.custom(status: .internalServerError, message: "Missing connected vendor for account with id \(account.id)")
            }

            vendor.missingFields = account.verification.fields_needed.count > 0
            vendor.needsIdentityUpload = account.requiresIdentityVerification

            return Response(status: .ok)
        }
    }
}
