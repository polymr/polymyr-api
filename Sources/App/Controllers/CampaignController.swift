//
//  CampaignController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/4/17.
//
//

import HTTP
import Vapor
import Fluent
import FluentProvider

final class CampaignController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        return try Campaign.all().makeResponse()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let campaign: Campaign = try request.extractModel(injecting: request.makerInjectable())
        try campaign.save()
        return try campaign.makeResponse()
    }
    
    func delete(_ request: Request, campaign: Campaign) throws -> ResponseRepresentable {
        try campaign.delete()
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, campaign: Campaign) throws -> ResponseRepresentable {
        let campaign: Campaign = try request.patchModel(campaign)
        try campaign.save()
        return try campaign.makeResponse()
    }
    
    func makeResource() -> Resource<Campaign> {
        return Resource(
            index: index,
            store: create,
            modify: modify,
            destroy: delete
        )
    }
}
