//
//  FileUpload.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/19/17.
//
//

import Node
import Foundation

public enum UploadReason: String, NodeConvertible {
    
    case business_logo
    case dispute_evidence
    case identity_document
    case incorporation_article
    case incorporation_document
    case invoice_statement
    case payment_provider_transfer
    case product_feed
    
    var maxSize: Int {
        switch self {
        case .identity_document: fallthrough
        case .business_logo: fallthrough
        case .incorporation_article: fallthrough
        case .incorporation_document: fallthrough
        case .invoice_statement: fallthrough
        case .invoice_statement: fallthrough
        case .payment_provider_transfer: fallthrough
        case .product_feed:
            return 8 * 1000000
            
        case .dispute_evidence:
            return 4 * 1000000
        }
    }
    
    var allowedMimeTypes: [String] {
        switch self {
        case .identity_document: fallthrough
        case .business_logo: fallthrough
        case .incorporation_article: fallthrough
        case .incorporation_document: fallthrough
        case .invoice_statement: fallthrough
        case .invoice_statement: fallthrough
        case .payment_provider_transfer: fallthrough
        case .product_feed:
            return ["image/jpeg", "image/png"]
            
        case .dispute_evidence:
            return ["image/jpeg", "image/png", "application/pdf"]
        }
    }
}

public enum FileType: String, NodeConvertible {
    
    case pdf
    case xml
    case jpg
    case png
    case csv
    case tsv
}

public final class FileUpload: NodeConvertible {
    
    static let type = "file_upload"
    
    public let id: String
    public let created: Date
    public let purpose: UploadReason
    public let size: Int
    public let type: FileType
    public let url: String?
    
    public init(node: Node) throws {
        guard try node.get("object") == FileUpload.type else {
            throw NodeError.unableToConvert(input: node, expectation: FileUpload.type, path: ["object"])
        }
        
        id = try node.get("id")
        created = try node.get("created")
        purpose = try node.get("purpose")
        size = try node.get("size")
        type = try node.get("type")
        url = try node.get("url")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "id" : .string(id),
            "created" : try created.makeNode(in: context),
            "purpose" : try purpose.makeNode(in: context),
            "size" : .number(.int(size)),
            "type" : try type.makeNode(in: context)
        ]).add(objects: [
            "url" : url
        ])
    }
}
