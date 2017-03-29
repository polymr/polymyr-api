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

final class AnswerController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        return try Answer.all().makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var answer: Answer = try request.extractModel(injecting: request.customerInjectable())
        try answer.save()
        return answer
    }
    
    func delete(_ request: Request, answer: Answer) throws -> ResponseRepresentable {
        try answer.delete()
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, answer: Answer) throws -> ResponseRepresentable {
        var answer: Answer = try request.patchModel(answer)
        try answer.save()
        return try Response(status: .ok, json: answer.makeJSON())
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
