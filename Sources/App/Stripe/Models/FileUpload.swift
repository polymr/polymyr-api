//
//  FileUpload.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/19/17.
//
//

import Node

#if os(macOS)
    import Foundation.NSDate
#else
    import Foundation.Date
#endif

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
    
    public init(node: Node, in context: Context = EmptyNode) throws {
        guard try node.extract("object") == FileUpload.type else {
            throw NodeError.unableToConvert(node: node, expected: FileUpload.type)
        }
        
        id = try node.extract("id")
        created = try node.extract("created")
        purpose = try node.extract("purpose")
        size = try node.extract("size")
        type = try node.extract("type")
        url = try node.extract("url")
    }
    
    public func makeNode(context: Context = EmptyNode) throws -> Node {
        return try Node(node: [
            "id" : .string(id),
            "created" : try created.makeNode(),
            "purpose" : try purpose.makeNode(),
            "size" : .number(.int(size)),
            "type" : try type.makeNode()
        ]).add(objects: [
            "url" : url
        ])
    }
}
