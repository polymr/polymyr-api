//
//  MakerController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/15/16.
//
//

import Vapor
import HTTP
import AuthProvider

extension Maker {
    
    func shouldAllow(request: Request) throws {
        guard let maker = try? request.maker() else {
            throw try Abort.custom(status: .forbidden, message: "Method \(request.method) is not allowed on resource Maker(\(throwableId())) by this user. Must be logged in as Maker(\(throwableId())).")
        }

        guard try maker.throwableId() == throwableId() else {
            throw try Abort.custom(status: .forbidden, message: "This Maker(\(maker.throwableId()) does not have access to resource Maker(\(throwableId()). Must be logged in as Maker(\(throwableId()).")
        }
    }
}

final class MakerController: ResourceRepresentable {

    func index(_ request: Request) throws -> ResponseRepresentable {
        return try request.maker().makeJSON()
    }
    
    func show(_ request: Request, maker: Maker) throws -> ResponseRepresentable {
        try maker.shouldAllow(request: request)
        return try maker.makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let maker: Maker = try request.extractModel()
        try maker.save()
        
        request.auth.authenticate(maker)

        return try maker.makeResponse()
    }

    func modify(_ request: Request, maker: Maker) throws -> ResponseRepresentable {
        try maker.shouldAllow(request: request)
        
        let maker: Maker = try request.patchModel(maker)
        try maker.save()
        
        return try maker.makeResponse()
    }
    
    func makeResource() -> Resource<Maker> {
        return Resource(
            index: index,
            store: create,
            show: show,
            modify: modify
        )
    }
}
    
