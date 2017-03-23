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
drop.picture(base: "makers", slug: "makers_id", picture: PictureController<MakerPicture>())

drop.resource("customers", CustomerController())
drop.picture(base: "customers", slug: "customer_id", picture: PictureController<CustomerPicture>())

drop.resource("products", ProductController())
drop.picture(base: "products", slug: "products_id", picture: PictureController<ProductPicture>())

drop.resource("questions", QuestionController())
drop.resource("campaigns", CampaignController())
drop.resource("answers", AnswerController())
drop.resource("orders", OrderController())
drop.resource("sections", SectionController())
drop.resource("customerAddresses", CustomerAddressController())
drop.resource("tags", TagController())
drop.resource("descriptions", DescriptionController())

drop.collection(StripeCollection.self)
drop.collection(AuthenticationCollection())

drop.run()
