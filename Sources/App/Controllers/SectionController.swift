//
//  SectionController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/4/17.
//
//

import Foundation
import HTTP
import Vapor
import Fluent

final class SectionController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        return try QuestionSection.all().makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var section: QuestionSection = try request.extractModel()
        try section.save()
        return section
    }
    
    func delete(_ request: Request, section: QuestionSection) throws -> ResponseRepresentable {
        try section.delete()
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, section: QuestionSection) throws -> ResponseRepresentable {
        var section: QuestionSection = try request.patchModel(section)
        try section.save()
        return try Response(status: .ok, json: section.makeJSON())
    }
    
    func makeResource() -> Resource<QuestionSection> {
        return Resource(
            index: index,
            store: create,
            modify: modify,
            destroy: delete
        )
    }
}
