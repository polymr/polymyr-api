//
//  AnswerController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/4/17.
//
//

import HTTP
import Vapor
import Fluent
import FluentProvider

final class AnswerController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        return try Answer.all().makeResponse()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let answer: Answer = try request.extractModel(injecting: request.customerInjectable())
        try answer.save()
        return try answer.makeResponse()
    }
    
    func delete(_ request: Request, answer: Answer) throws -> ResponseRepresentable {
        try answer.delete()
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, answer: Answer) throws -> ResponseRepresentable {
        let answer: Answer = try request.patchModel(answer)
        try answer.save()
        return try answer.makeResponse()
    }
    
    func makeResource() -> Resource<Answer> {
        return Resource(
            index: index,
            store: create,
            modify: modify,
            destroy: delete
        )
    }
}
