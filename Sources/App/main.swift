//
//  Main.swift
//  polymyr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import Fluent
import FluentProvider
import Node
import HTTP
import AuthProvider

let drop = Droplet.create()

AuthenticationCollection().build(drop)

let makerPasswordAuthMiddleWare = PasswordAuthenticationMiddleware(Maker.self)

let userTokenAuthMiddleware = TokenAuthenticationMiddleware(Customer.self)
let makerTokenAuthMiddleware = TokenAuthenticationMiddleware(Maker.self)

drop.group(middleware: [PersistMiddleware(Customer.self), PersistMiddleware(Maker.self)]) { drop in

    drop.resource("makers", MakerController())
    drop.picture(base: "makers", slug: "makers_id", picture: PictureController<MakerPicture, Maker>())

    drop.resource("customers", CustomerController())
    drop.picture(base: "customers", slug: "customer_id", picture: PictureController<CustomerPicture, Customer>())

    drop.resource("products", ProductController())
    drop.picture(base: "products", slug: "products_id", picture: PictureController<ProductPicture, Product>())

    drop.resource("questions", QuestionController())
    drop.resource("campaigns", CampaignController())
    drop.resource("answers", AnswerController())
    drop.resource("orders", OrderController())
    drop.resource("sections", SectionController())
    drop.resource("customerAddresses", CustomerAddressController())
    drop.resource("tags", TagController())

    StripeCollection().build(drop)

    drop.group(middleware: [makerTokenAuthMiddleware, userTokenAuthMiddleware]) { authenticated in

    }
}

do {
    try drop.run()
} catch {
    fatalError("Error while running droplet : \(error)")
}
