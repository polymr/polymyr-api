//
//  DisputeEvidence.swift
//  Stripe
//
//  Created by Hakon Hanesand on 1/1/17.
//
//

import Node

public final class DisputeEvidence: NodeConvertible {

    public let access_activity_log: String?
    public let billing_address: String?
    public let cancellation_policy: String?
    public let cancellation_policy_disclosure: String?
    public let cancellation_rebuttal: String?
    public let customer_communication: String?
    public let customer_email_address: String?
    public let customer_name: String?
    public let customer_purchase_ip: String?
    public let customer_signature: String?
    public let duplicate_charge_documentation: String?
    public let duplicate_charge_explanation: String?
    public let duplicate_charge_id: String?
    public let product_description: String?
    public let receipt: String?
    public let refund_policy: String?
    public let refund_policy_disclosure: String?
    public let refund_refusal_explanation: String?
    public let service_date: String?
    public let service_documentation: String?
    public let shipping_address: String?
    public let shipping_carrier: String?
    public let shipping_date: String?
    public let shipping_documentation: String?
    public let shipping_tracking_number: String?
    public let uncategorized_file: String?
    public let uncategorized_text: String?

    public init(node: Node) throws {

        access_activity_log = try node.extract("access_activity_log")
        billing_address = try node.extract("billing_address")
        cancellation_policy = try node.extract("cancellation_policy")
        cancellation_policy_disclosure = try node.extract("cancellation_policy_disclosure")
        cancellation_rebuttal = try node.extract("cancellation_rebuttal")
        customer_communication = try node.extract("customer_communication")
        customer_email_address = try node.extract("customer_email_address")
        customer_name = try node.extract("customer_name")
        customer_purchase_ip = try node.extract("customer_purchase_ip")
        customer_signature = try node.extract("customer_signature")
        duplicate_charge_documentation = try node.extract("duplicate_charge_documentation")
        duplicate_charge_explanation = try node.extract("duplicate_charge_explanation")
        duplicate_charge_id = try node.extract("duplicate_charge_id")
        product_description = try node.extract("product_description")
        receipt = try node.extract("receipt")
        refund_policy = try node.extract("refund_policy")
        refund_policy_disclosure = try node.extract("refund_policy_disclosure")
        refund_refusal_explanation = try node.extract("refund_refusal_explanation")
        service_date = try node.extract("service_date")
        service_documentation = try node.extract("service_documentation")
        shipping_address = try node.extract("shipping_address")
        shipping_carrier = try node.extract("shipping_carrier")
        shipping_date = try node.extract("shipping_date")
        shipping_documentation = try node.extract("shipping_documentation")
        shipping_tracking_number = try node.extract("shipping_tracking_number")
        uncategorized_file = try node.extract("uncategorized_file")
        uncategorized_text = try node.extract("uncategorized_text")
    }

    public func makeNode(in context: Context?) throws -> Node {
        return try Node.object([:]).add(objects: [
            "access_activity_log" : access_activity_log,
            "billing_address" : billing_address,
            "cancellation_policy" : cancellation_policy,
            "cancellation_policy_disclosure" : cancellation_policy_disclosure,
            "cancellation_rebuttal" : cancellation_rebuttal,
            "customer_communication" : customer_communication,
            "customer_email_address" : customer_email_address,
            "customer_name" : customer_name,
            "customer_purchase_ip" : customer_purchase_ip,
            "customer_signature" : customer_signature,
            "duplicate_charge_documentation" : duplicate_charge_documentation,
            "duplicate_charge_explanation" : duplicate_charge_explanation,
            "duplicate_charge_id" : duplicate_charge_id,
            "product_description" : product_description,
            "receipt" : receipt,
            "refund_policy" : refund_policy,
            "refund_policy_disclosure" : refund_policy_disclosure,
            "refund_refusal_explanation" : refund_refusal_explanation,
            "service_date" : service_date,
            "service_documentation" : service_documentation,
            "shipping_address" : shipping_address,
            "shipping_carrier" : shipping_carrier,
            "shipping_date" : shipping_date,
            "shipping_documentation" : shipping_documentation,
            "shipping_tracking_number" : shipping_tracking_number,
            "uncategorized_file" : uncategorized_file,
            "uncategorized_text" : uncategorized_text
        ])
    }

}
