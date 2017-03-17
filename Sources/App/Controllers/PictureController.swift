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

fileprivate func handle(upload request: Request) throws -> String {
    guard let data = request.formData?.first?.value.part.body else {
        throw Abort.custom(status: .badRequest, message: "No file in request")
    }
    
    return try save(data: Data(bytes: data))
}

func save(data: Data) throws -> String {
    
    let imageFolder = "Public/images"
    
    guard let workPath = Droplet.instance?.workDir else {
        throw Abort.custom(status: .internalServerError, message: "Missing working directory")
    }
    
    let name = UUID().uuidString + ".png"
    let saveURL = URL(fileURLWithPath: workPath).appendingPathComponent(imageFolder, isDirectory: true).appendingPathComponent(name, isDirectory: false)
    
    do {
        try data.write(to: saveURL)
    } catch {
        throw Abort.custom(status: .internalServerError, message: "Unable to write multipart form data to file. Underlying error \(error)")
    }
    
    return "https://static.polymyr.com/images/" + name
}

final class PictureController<PictureType: Picture> {
    
    func index(_ request: Request, owner: Int) throws -> ResponseRepresentable {
        return try PictureType.query().filter("owner_id", owner).all().makeJSON()
    }

    func create(_ request: Request, owner: Int) throws -> ResponseRepresentable {
        let url = try handle(upload: request)

        var picture = try PictureType.init(node: Node(node: ["owner_id" : owner, "url" : url]).add(name: "type", node: request.query?["type"]))
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

