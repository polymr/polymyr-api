//
//  StripeCollection.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/1/17.
//
//

import HTTP
import Routing
import Vapor
import Node

#if os(macOS)
    import Foundation.NSDate
#endif

extension Sequence where Iterator.Element == Bool {
    
    public func all() -> Bool {
        return reduce(true) { $0 && $1 }
    }
}

extension NodeConvertible {

    public func makeResponse() throws -> Response {
        return try Response(status: .ok, json: self.makeNode().makeJSON())
    }
}

extension Sequence where Iterator.Element == (key: String, value: String) {
    
    func reduceDictionary() -> [String : String] {
        return flatMap { $0 }.reduce([:]) { (_dict, tuple) in
            var dict = _dict
            dict.updateValue(tuple.1, forKey: tuple.0)
            return dict
        }
    }
}

fileprivate func stripeKeyPathFor(base: String, appending: String) -> String {
    if base.characters.count == 0 {
        return appending
    }
    
    return "\(base)[\(appending)]"
}

extension Node {
    
    var isLeaf : Bool {
        switch self {
        case .array(_), .object(_):
            return false
            
        case .bool(_), .bytes(_), .string(_), .number(_), .null:
            return true
        }
    }

    func collected() throws -> [String : String] {
        return collectLeaves(prefix: "")
    }
    
    private func collectLeaves(prefix: String) -> [String : String] {
        switch self {
        case let .array(nodes):
            return nodes.map { $0.collectLeaves(prefix: prefix) }.joined().reduceDictionary()
            
        case let .object(object):
            return object.map { $1.collectLeaves(prefix: stripeKeyPathFor(base: prefix, appending: $0)) }.joined().reduceDictionary()
            
        case .bool(_), .bytes(_), .string(_), .number(_):
            return [prefix : string ?? ""]
            
        case .null:
            return [:]
        }
    }
}

class StripeCollection: RouteCollection, EmptyInitializable {

    required init() { }

    typealias Wrapped = HTTP.Responder

    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {

        builder.group("stripe") { stripe in
    
            stripe.group("customer") { customer in

                customer.group("sources") { sources in
                    
                    sources.post("default", String.self) { request, source in
                        guard let id = try request.customer().stripe_id else {
                            throw try Abort.custom(status: .badRequest, message: "user \(request.customer().throwableId()) doesn't have a stripe account")
                        }
                        
                        return try Stripe.shared.update(customer: id, parameters: ["default_source" : source]).makeResponse()
                    }

                    sources.post(String.self) { request, source in

                        guard var customer = try? request.customer() else {
                            throw Abort.custom(status: .forbidden, message: "Log in first.")
                        }
                        
                        if let stripe_id = customer.stripe_id {
                            return try Stripe.shared.associate(source: source, withStripe: stripe_id).makeResponse()
                        } else {
                            let stripeCustomer = try Stripe.shared.createNormalAccount(email: customer.email, source: source, local_id: customer.id?.int)
                            customer.stripe_id = stripeCustomer.id
                            try customer.save()
                            return try stripeCustomer.makeResponse()
                        }
                    }

                    sources.delete(String.self) { request, source in

                        guard let customer = try? request.customer() else {
                            throw Abort.custom(status: .forbidden, message: "Log in first.")
                        }

                        guard let id = customer.stripe_id else {
                            throw Abort.custom(status: .badRequest, message: "User \(customer.id!.int!) doesn't have a stripe account.")
                        }

                        return try Stripe.shared.delete(payment: source, from: id).makeResponse()
                    }
                    
                    sources.get() { request in
                        guard let customer = try? request.customer(), let stripeId = customer.stripe_id else {
                            throw Abort.badRequest
                        }
                        
                        let cards = try Stripe.shared.paymentInformation(for: stripeId).map { try $0.makeNode() }
                        return try Node.array(cards).makeResponse()
                    }
                }
            }
            
            stripe.get("country", "verification", String.self) { request, country_code in
                guard let country = try? CountryCode(node: country_code) else {
                    throw Abort.custom(status: .badRequest, message: "\(country_code) is not a valid country code.")
                }
                
                return try Stripe.shared.verificationRequiremnts(for: country).makeNode().makeResponse()
            }

            stripe.group("maker") { maker in

                maker.get("disputes") { request in
                    return try Stripe.shared.disputes().makeNode().makeResponse()
                }

                maker.post("create") { request in
                    var maker = try request.maker()
                    let account = try Stripe.shared.createManagedAccount(email: maker.contactEmail, local_id: maker.id?.int)
                    
                    maker.stripe_id = account.id
                    maker.keys = account.keys
                    try maker.save()
                    
                    return try maker.makeResponse()
                }

                maker.post("acceptedtos", String.self) { request, ip in
                    let maker = try request.maker()

                    guard let stripe_id = maker.stripe_id else {
                        throw Abort.custom(status: .badRequest, message: "Missing stripe id")
                    }

                    return try Stripe.shared.acceptedTermsOfService(for: stripe_id, ip: ip).makeNode().makeResponse()
                }
                
                maker.get("verification") { request in
                    let maker = try request.maker()
                    
                    guard let stripe_id = maker.stripe_id else {
                        throw Abort.custom(status: .badRequest, message: "maker does not have stripe id.")
                    }
                    
                    let account = try Stripe.shared.makerInformation(for: stripe_id)

                    return try Node.object([
                        "fields" : try account.descriptionsForNeededFields().makeNode()
                    ]).add(objects: [
                        "due_by" : account.verification.due_by?.ISO8601String,
                        "disabled_reason" : account.verification.disabled_reason?.rawValue,
                        "identity" : account.legal_entity.verification.status != .verified ? account.legal_entity.verification.makeNode() : nil
                    ]).makeJSON()
                }
                
                maker.get("payouts") { request in
                    let maker = try request.maker()
                    
                    guard let secretKey = maker.keys?.secret else {
                        throw Abort.custom(status: .badRequest, message: "maker is missing stripe id.")
                    }
                    
                    return try Stripe.shared.transfers(for: secretKey).makeNode().makeResponse()
                }
                
                maker.post("verification") { request in
                    let maker = try request.maker()
                    
                    guard let stripe_id = maker.stripe_id else {
                        throw Abort.custom(status: .badRequest, message: "maker does not have stripe id")
                    }
                    
                    let account = try Stripe.shared.makerInformation(for: stripe_id)
                    let fieldsNeeded = account.filteredNeededFieldsWithCombinedDateOfBirth()
                    var node = try request.json().permit(fieldsNeeded).node
                    
                    if node.nodeObject?.keys.contains(where: { $0.hasPrefix("external_account") }) ?? false {
                        node["external_account.object"] = "bank_account"
                    }

                    if node["legal_entity.dob"] != nil {
                        guard let unix = node["legal_entity.dob"]?.string else { throw Abort.custom(status: .badRequest, message: "Could not parse unix time from updates)") }
                        guard let timestamp = Int(unix) else { throw Abort.custom(status: .badRequest, message: "Could not get number from unix : \(unix)") }
                        
                        let calendar = Calendar.current
                        let date = Date(timeIntervalSince1970: Double(timestamp))
                        
                        node["legal_entity.dob"] = nil
                        node["legal_entity.dob.day"] = .string("\(calendar.component(.day, from: date))")
                        node["legal_entity.dob.month"] = .string("\(calendar.component(.month, from: date))")
                        node["legal_entity.dob.year"] = .string("\(calendar.component(.year, from: date))")
                    }
                    
                    var updates: [String : String] = [:]
                    
                    try node.nodeObject?.forEach {
                        guard let string = $1.string else {
                            throw Abort.custom(status: .badRequest, message: "could not convert object at key \($0) to string.")
                        }
                        
                        var split = $0.components(separatedBy: ".")
                        
                        if split.count == 1 {
                            updates[$0] = string
                            return
                        }
                        
                        var key = split[0]
                        split.remove(at: 0)

                        key = key + split.reduce("") { $0 + "[\($1)]" }
                        
                        updates[key] = string
                    }
                    
                    return try Stripe.shared.updateAccount(id: stripe_id, parameters: updates).makeResponse()
                }
                
                maker.post("upload", String.self) { request, _uploadReason in
                    let maker = try request.maker()
                    
                    guard let uploadReason = try UploadReason(from: _uploadReason) else {
                        throw Abort.custom(status: .badRequest, message: "\(_uploadReason) is not an acceptable reason.")
                    }
                    
                    if uploadReason != .identity_document {
                        throw Abort.custom(status: .badRequest, message: "Currently only \(UploadReason.identity_document.rawValue) is supported")
                    }
                    
                    guard let fileField = request.formData?.allItems.first?.1 else {
                        throw Abort.custom(status: .badRequest, message: "Missing file to upload.")
                    }
                    
                    guard let name = fileField.filename, let type = NSURL(fileURLWithPath: name).deletingPathExtension?.lastPathComponent, let fileType = try FileType(from: type) else {
                        throw Abort.custom(status: .badRequest, message: "Misisng upload file type.")
                    }
                    
                    guard let stripe_id = maker.stripe_id else {
                        throw Abort.custom(status: .badRequest, message: "maker with id \(maker.id?.int ?? 0) does't have a stripe acocunt yet. Call /maker/create/{token_id} to create one.")
                    }
                    
                    let fileUpload = try Stripe.shared.upload(file: fileField.part.body, with: uploadReason, type: fileType)
                    return try Stripe.shared.updateAccount(id: stripe_id, parameters: ["legal_entity[verification][document]" : fileUpload.id]).makeResponse()
                }
            }
        }
    }
}

