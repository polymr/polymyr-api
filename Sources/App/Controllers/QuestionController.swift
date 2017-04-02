//
//  QuestionController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/4/17.
//
//

import HTTP
import Vapor
import Fluent
import FluentProvider

final class QuestionController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        return try Question.all().makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let question: Question = try request.extractModel(injecting: request.makerInjectable())
        try question.save()
        return question
    }
    
    func delete(_ request: Request, question: Question) throws -> ResponseRepresentable {
        try question.delete()
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, question: Question) throws -> ResponseRepresentable {
        let question: Question = try request.patchModel(question)
        try question.save()
        return try Response(status: .ok, json: question.makeJSON())
    }
    
    func makeResource() -> Resource<Question> {
        return Resource(
            index: index,
            store: create,
            modify: modify,
            destroy: delete
        )
    }
}

