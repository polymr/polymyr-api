//
//  Main.swift
//  polymyr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import Node
import HTTP
import Turnstile
import Foundation
import Auth

let drop = Droplet.create()

drop.resource("makers", MakerController())
drop.resource("customers", CustomerController())
drop.resource("authentication", AuthenticationController())
drop.resource("products", ProductController())
drop.resource("questions", QuestionController())
drop.resource("campaigns", CampaignController())
drop.resource("orders", OrderController())
drop.resource("sections", SectionController())
drop.resource("customerAddresses", CustomerAddressController())

drop.run()
