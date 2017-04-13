//
//  PictureController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/8/17.
//
//

import HTTP
import Vapor
import Fluent
import FluentProvider
import Routing

extension RouteBuilder {
    
    func picture<PictureType: Picture, OwnerType: Entity>(base path: String, slug: String, picture controller: PictureController<PictureType, OwnerType>) {
        self.add(.get, path, ":\(slug)", "pictures") { request in
            guard let owner = request.parameters[slug]?.converted(to: Identifier.self) else {
                throw TypeSafeRoutingError.missingParameter
            }
        
            return try controller.index(request, owner: owner).makeResponse()
        }
        
        self.add(.post, path, ":\(slug)", "pictures") { request in
            guard let owner = request.parameters[slug]?.converted(to: Identifier.self) else {
                throw TypeSafeRoutingError.missingParameter
            }

            return try controller.create(request, owner: owner).makeResponse()
        }
        
        self.add(.delete, path, ":\(slug)", "pictures", ":picture_id") { request in
            guard let owner = request.parameters[slug]?.converted(to: Identifier.self) else {
                throw TypeSafeRoutingError.missingParameter
            }
            
            guard let picture_id = request.parameters["picture_id"]?.int else {
                throw TypeSafeRoutingError.missingParameter
            }
            
            return try controller.delete(request, owner: owner, picture: picture_id).makeResponse()
        }
    }
}

final class PictureController<PictureType: Picture, OwnerType: Entity> {
    
    func index(_ request: Request, owner: Identifier) throws -> ResponseRepresentable {
        return try PictureType.pictures(for: owner).all().makeJSON()
    }

    func createPicture(from nodeObject: Node, with owner: Identifier) throws -> PictureType {
        let context = ParentContext(parent_id: owner)
        let picture = try PictureType(node: Node(nodeObject.permit(PictureType.permitted).wrapped, in: context))
        try picture.save()
        return picture
    }

    func create(_ request: Request, owner: Identifier) throws -> ResponseRepresentable {
        guard let node = request.json?.node else {
            throw Abort.custom(status: .badRequest, message: "Missing json.")
        }

        if let array = node.array {
            return try Node.array(array.map {
                try createPicture(from: $0, with: owner).makeNode(in: jsonContext)
            }).makeResponse()
        } else {
            return try createPicture(from: node, with: owner).makeJSON()
        }
    }
    
    func delete(_ request: Request, owner: Identifier, picture: Int) throws -> ResponseRepresentable {
        guard let picture = try PictureType.find(picture) else {
            throw Abort.custom(status: .badRequest, message: "No such picture exists.")
        }
        
        try picture.delete()
        return Response(status: .noContent)
    }
}

