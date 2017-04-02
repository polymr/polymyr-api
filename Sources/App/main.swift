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

let makerPasswordAuthMiddleWare = PasswordAuthenticationMiddleware(Maker.self)

let userTokenAuthMiddleware = TokenAuthenticationMiddleware(Customer.self)
let makerTokenAuthMiddleware = TokenAuthenticationMiddleware(Maker.self)

let userPersist = PersistMiddleware(Customer.self)
let makerPersist = PersistMiddleware(Maker.self)

drop.group(middleware: [makerPasswordAuthMiddleWare, userTokenAuthMiddleware]) { authenticated in
    authenticated.resource("makers", MakerController())
    authenticated.picture(base: "makers", slug: "makers_id", picture: PictureController<MakerPicture, Maker>())

    authenticated.resource("customers", CustomerController())
    authenticated.picture(base: "customers", slug: "customer_id", picture: PictureController<CustomerPicture, Customer>())

    authenticated.resource("products", ProductController())
    authenticated.picture(base: "products", slug: "products_id", picture: PictureController<ProductPicture, Product>())

    authenticated.resource("questions", QuestionController())
    authenticated.resource("campaigns", CampaignController())
    authenticated.resource("answers", AnswerController())
    authenticated.resource("orders", OrderController())
    authenticated.resource("sections", SectionController())
    authenticated.resource("customerAddresses", CustomerAddressController())
    authenticated.resource("tags", TagController())

    StripeCollection().build(authenticated)
    AuthenticationCollection().build(authenticated)
}

do {
    try drop.run()
} catch {
    fatalError("Error while running droplet : \(error)")
}
