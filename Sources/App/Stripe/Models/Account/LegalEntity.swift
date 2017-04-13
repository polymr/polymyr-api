//
//  LegalEntityVerification.swift
//  Stripe
//
//  Created by Hakon Hanesand on 1/18/17.
//
//

import Node

public enum LegalEntityVerificationStatus: String, NodeConvertible {
    
    case unverified
    case pending
    case verified
}

public enum LegalEntityVerificationFailureReason: String, NodeConvertible {
    
    case scan_corrupt
    case scan_not_readable
    case scan_failed_greyscale
    case scan_not_uploaded
    case scan_id_type_not_supported
    case scan_id_country_not_supported
    case scan_name_mismatch
    case scan_failed_other
    case failed_keyed_identity
    case failed_other
}

public final class LegalEntityIdentityVerification: NodeConvertible {
    
    public let status: LegalEntityVerificationStatus
    public let document: Document?
    public let details: String?
    public let details_code: LegalEntityVerificationFailureReason?
    
    public required init(node: Node) throws {
        status = try node.extract("status")
        document = try? node.extract("document")
        details = try? node.extract("details")
        details_code = try? node.extract("details_code")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "status" : try status.makeNode(in: context),
        ] as [String : Node]).add(objects: [
            "details" : details,
            "document" : document,
            "details_code" : details_code
        ])
    }
}

public enum LegalEntityType: String, NodeConvertible {
    
    case individual
    case company
}

public final class LegalEntity: NodeConvertible {
    
    public let address: Address
    public let business_name: String?
    public let business_tax_id_provided: Bool
    public let dob: DateOfBirth
    public let first_name: String?
    public let last_name: String?
    public let personal_address: Address
    public let personal_id_number_provided: Bool
    public let ssn_last_4_provided: Bool
    public let type: String?
    public let verification: LegalEntityIdentityVerification
    
    public required init(node: Node) throws {
        address = try node.extract("address")
        business_name = try? node.extract("business_name")
        business_tax_id_provided = try node.extract("business_tax_id_provided")
        dob = try node.extract("dob")
        first_name = try? node.extract("first_name")
        last_name = try? node.extract("last_name")
        personal_address = try node.extract("personal_address")
        personal_id_number_provided = try node.extract("personal_id_number_provided")
        ssn_last_4_provided = try node.extract("ssn_last_4_provided")
        type = try? node.extract("type")
        verification = try node.extract("verification")
    }
    
    public func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "address" : try address.makeNode(in: context),
            "business_tax_id_provided" : .bool(business_tax_id_provided),
            "dob" : try dob.makeNode(in: context),
            "personal_address" : try personal_address.makeNode(in: context),
            "personal_id_number_provided" : .bool(personal_id_number_provided),
            "ssn_last_4_provided" : .bool(ssn_last_4_provided),
            "verification" : try verification.makeNode(in: context)
        ] as [String : Node]).add(objects: [
            "business_name" : business_name,
            "first_name" : first_name,
            "last_name" : last_name,
            "type" : type
        ])
    }
    
    static func descriptionForNeededFields(in country: CountryType, for field: String) -> [String : Node] {
        switch field {
        case "legal_entity.business_name":
            return ["name" : "Business Name", "description" : "The publicly visible name of your business", "key" : .string(field)]
        case "legal_entity.business_tax_id":
            return ["name" : "Business Tax ID", "description" : "The tax ID number of your business.", "key" : .string(field)]
            
        case let field where field.hasPrefix("legal_entity.address"):
            switch field {
            case "legal_entity.address.city":
                return ["name" : "City", "description" : "The city your business is registered in.", "key" : .string(field)]
            case "legal_entity.address.line1":
                return ["name" : "Address", "description" : "The address of your business.", "key" : .string(field)]
            case "legal_entity.address.postal_code":
                return ["name" : "Postal Code", "description" : "The postal code your business is registered in.", "key" : .string(field)]
            case "legal_entity.address.state":
                return ["name" : "State", "description" : "The state your business is registered in.", "key" : .string(field)]
            default:
                return ["name" : "", "description" : "", "key" : .string(field)]
            }

        case let field where field.hasSuffix("document"):
            return ["name" : "Identity Verification", "upload" : true, "upload_info" : Node.object(["url" : "https://uploads.stripe.com/v1/files", "purpose" : "identity_document", "api_key" : .string(Stripe.token)])]
            
        case "legal_entity.dob":
            return ["name" : "Date of Birth", "description" : "The date of birth for your company representative.", "key" : .string(field)]
            
        case "legal_entity.first_name":
            return ["name" : "First Name", "description" : "The first name of your company representative.", "key" : .string(field)]
        case "legal_entity.last_name":
            return ["name" : "Last Name", "description": "The last name of your company representative.", "key" : .string(field)]
            
        case "legal_entity.ssn_last_4":
            return ["name" : "Last 4 of Social Security number", "description" : "The last four digits of the company representative's SSN.", "key" : .string(field)]
        case "legal_entity.type":
            return ["name" : "Always company.", "description" : "Always company", "key" : .string(field)]

        default:
            return ["name" : "", "description" : "", "key" : .string(field)]
        }
    }
}
