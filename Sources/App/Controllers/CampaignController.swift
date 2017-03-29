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

final class CampaignController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        return try Campaign.all().makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var campaign: Campaign = try request.extractModel(injecting: request.makerInjectable())
        try campaign.save()
        return campaign
    }
    
    func delete(_ request: Request, campaign: Campaign) throws -> ResponseRepresentable {
        try campaign.delete()
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, campaign: Campaign) throws -> ResponseRepresentable {
        var campaign: Campaign = try request.patchModel(campaign)
        try campaign.save()
        return try Response(status: .ok, json: campaign.makeJSON())
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
