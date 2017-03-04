//
//  VendorController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/15/16.
//
//

import Foundation
import Vapor
import HTTP
import Turnstile
import Auth

extension Vendor {
    
    func shouldAllow(request: Request) throws {
        guard let vendor = try? request.vendor() else {
            throw try Abort.custom(status: .forbidden, message: "Method \(request.method) is not allowed on resource Vendor(\(throwableId())) by this user. Must be logged in as Vendor(\(throwableId())).")
        }

        guard try vendor.throwableId() == throwableId() else {
            throw try Abort.custom(status: .forbidden, message: "This Vendor(\(vendor.throwableId()) does not have access to resource Vendor(\(throwableId()). Must be logged in as Vendor(\(throwableId()).")
        }
    }
}

final class VendorController: ResourceRepresentable {

    func index(_ request: Request) throws -> ResponseRepresentable {
        return try request.vendor().makeJSON()
    }
    
    func show(_ request: Request, vendor: Vendor) throws -> ResponseRepresentable {
        try vendor.shouldAllow(request: request)
        return try vendor.makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var vendor: Vendor = try request.extractModel()
        try vendor.save()
        
        let node = try request.json().node
        let username: String = try node.extract("username")
        let password: String = try node.extract("password")
        
        let usernamePassword = UsernamePassword(username: username, password: password)
        try request.vendorSubject().login(credentials: usernamePassword, persist: true)
        
        return vendor
    }

    func modify(_ request: Request, vendor: Vendor) throws -> ResponseRepresentable {
        try vendor.shouldAllow(request: request)
        
        var vendor: Vendor = try request.patchModel(vendor)
        try vendor.save()
        return try Response(status: .ok, json: vendor.makeJSON())
    }
    
    func makeResource() -> Resource<Vendor> {
        return Resource(
            index: index,
            store: create,
            show: show,
            modify: modify
        )
    }
}
    
