//
//  IdentityVerification.swift
//  Stripe
//
//  Created by Hakon Hanesand on 1/18/17.
//
//

import Node
import Foundation

public enum IdentityVerificationFailureReason: String, NodeConvertible {
    
    case fraud = "rejected.fraud"
    case tos = "rejected.terms_of_service"
    case rejected_listed = "rejected.listed"
    case rejected_other = "rejected.other"
    case fields_needed
    case listed
    case other
}

public final class IdentityVerification: NodeConvertible {
    
    public let disabled_reason: IdentityVerificationFailureReason?
    public let due_by: Date?
    public let fields_needed: [String]
    
    public required init(node: Node) throws {
        disabled_reason = try? node.extract("disabled_reason")
        due_by = try? node.extract("due_by")
        fields_needed = try node.extract("fields_needed")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "fields_needed" : .array(fields_needed.map { Node.string($0) } )
        ] as [String : Node]).add(objects: [
            "due_by" : due_by,
            "disabled_reason" : disabled_reason
        ])
    }
}
