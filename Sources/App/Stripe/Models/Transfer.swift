//
//  Transfer.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/31/17.
//
//

import Node
import Foundation

public enum SourceType: String, NodeConvertible {
    
    case alipay_account
    case bank_account
    case bitcoin_receiver
    case card
}

public enum ChargeMethod: String, NodeConvertible {
    
    case standard
    case instant
}

public enum TransferStatus: String, NodeConvertible {
    
    case pending
    case paid
    case failed
    case in_transit
    case canceled
}

public final class Transfer: NodeConvertible {
    
    static let type = "transfer"
    
    public let id: String
    public let amount: Int
    public let amount_reversed: Int
    public let application_fee: String?
    public let balance_transaction: String
    public let created: Date
    public let currency: Currency
    public let date: Date
    public let description: String
    public let destination: String
    public let failure_code: String?
    public let failure_message: String?
    public let livemode: Bool
    public let metadata: Node
    public let method: ChargeMethod
    public let recipient: Node // [TransferReversal]
    public let reversals: String
    public let reversed: Bool
    public let source_transaction: String?
    public let source_type: SourceType
    public let statement_descriptor: String?
    public let status: TransferStatus
    public let transfer_group: String?
    public let type: String
    
    public init(node: Node) throws {
        guard try node.extract("object") == Transfer.type else {
            throw NodeError.unableToConvert(input: node, expectation: Transfer.type, path: ["object"])
        }
        
        id = try node.extract("id")
        amount = try node.extract("amount")
        amount_reversed = try node.extract("amount_reversed")
        application_fee = try? node.extract("application_fee")
        balance_transaction = try node.extract("balance_transaction")
        created = try node.extract("created")
        currency = try node.extract("currency")
        date = try node.extract("date")
        description = try node.extract("description")
        destination = try node.extract("destination")
        failure_code = try? node.extract("failure_code")
        failure_message = try? node.extract("failure_message")
        livemode = try node.extract("livemode")
        metadata = try node.extract("metadata")
        method = try node.extract("method")
        recipient = try node.extract("recipient")
        reversals = try node.extract("reversals")
        reversed = try node.extract("reversed")
        source_transaction = try? node.extract("source_transaction")
        source_type = try node.extract("source_type")
        statement_descriptor = try? node.extract("statement_descriptor")
        status = try node.extract("status")
        transfer_group = try? node.extract("transfer_group")
        type = try node.extract("type")
    }

    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "id" : id,
            "amount" : amount,
            "amount_reversed" : amount_reversed,
            "balance_transaction" : balance_transaction,
            "created" : created,
            "currency" : currency,
            "date" : date,
            "description" : description,
            "destination" : destination,
            "livemode" : livemode,
            "metadata" : metadata,
            "method" : method,
            "recipient" : recipient,
            "reversals" : reversals,
            "reversed" : reversed,
            "source_type" : source_type,
            "status" : status,
            "type" : type
        ]).add(objects: [
            "application_fee" : application_fee,
            "source_transaction" : source_transaction,
            "failure_code" : failure_code,
            "failure_message" : failure_message,
            "statement_descriptor" : statement_descriptor,
            "transfer_group" : transfer_group
        ])
    }
}
