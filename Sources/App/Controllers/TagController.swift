//
//  TagController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/4/17.
//
//

import HTTP
import Vapor
import Fluent
import FluentProvider

final class TagController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        return try Tag.all().makeJSON()
    }
    
    func show(_ request: Request, tag: Tag) throws -> ResponseRepresentable {
        return try tag.products().all().makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let tag: Tag = try request.extractModel()
        try tag.save()
        return try tag.makeResponse()
    }
    
    func delete(_ request: Request, tag: Tag) throws -> ResponseRepresentable {
        for product in try tag.products().all() {
            try tag.products().remove(product)
            try product.tags().remove(tag)
        }
        
        try tag.delete()
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, tag: Tag) throws -> ResponseRepresentable {
        let tag: Tag = try request.patchModel(tag)
        try tag.save()
        return try Response(status: .ok, json: tag.makeJSON())
    }
    
    func makeResource() -> Resource<Tag> {
        return Resource(
            index: index,
            store: create,
            show: show,
            modify: modify,
            destroy: delete
        )
    }
}
