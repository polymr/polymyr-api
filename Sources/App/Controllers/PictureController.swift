//
//  PictureController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/8/17.
//
//

import Foundation
import HTTP
import Vapor
import Fluent
import Routing

extension RouteBuilder where Value == Responder {
    
    func picture<PictureType: Picture>(base path: String, slug: String, picture controller: PictureController<PictureType>) {
        self.add(.get, path, ":\(slug)", "pictures") { request in
            guard let owner = request.parameters[slug]?.int else {
                throw TypeSafeRoutingError.missingParameter
            }
        
            return try controller.index(request, owner: owner).makeResponse()
        }
        
        self.add(.post, path, ":\(slug)", "pictures") { request in
            guard let owner = request.parameters[slug]?.int else {
                throw TypeSafeRoutingError.missingParameter
            }

            return try controller.create(request, owner: owner).makeResponse()
        }
        
        self.add(.delete, path, ":\(slug)", "pictures", ":picture_id") { request in
            guard let owner = request.parameters[slug]?.int else {
                throw TypeSafeRoutingError.missingParameter
            }
            
            guard let picture_id = request.parameters["picture_id"]?.int else {
                throw TypeSafeRoutingError.missingParameter
            }
            
            return try controller.delete(request, owner: owner, picture: picture_id).makeResponse()
        }
    }
}

final class PictureController<PictureType: Picture> {
    
    func index(_ request: Request, owner: Int) throws -> ResponseRepresentable {
        return try PictureType.query().filter("owner_id", owner).all().makeJSON()
    }

    func create(_ request: Request, owner: Int) throws -> ResponseRepresentable {
        var picture: PictureType = try request.extractModel(injecting: Node.object(["owner_id" : .number(.int(owner))]))
        try picture.save()
        return picture
    }
    
    func delete(_ request: Request, owner: Int, picture: Int) throws -> ResponseRepresentable {
        guard let picture = try PictureType.find(picture) else {
            throw Abort.custom(status: .badRequest, message: "No such picture exists.")
        }
        
        try picture.delete()
        return Response(status: .noContent)
    }
}

