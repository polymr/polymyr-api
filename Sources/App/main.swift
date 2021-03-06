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
import Foundation

let drop = Droplet.create()

let formatter = DateFormatter()
formatter.locale = Locale(identifier: "en_US_POSIX")
formatter.timeZone = TimeZone(secondsFromGMT: 0)
formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"

Date.incomingDateFormatters.append(formatter)

drop.group(middleware: [PersistMiddleware(Customer.self), PersistMiddleware(Maker.self)]) { persistable in
    
    AuthenticationCollection().build(persistable)

    persistable.resource("makers", MakerController())
    persistable.picture(base: "makers", slug: "makers_id", picture: PictureController<MakerPicture, Maker>())

    persistable.resource("customers", CustomerController())
    persistable.picture(base: "customers", slug: "customer_id", picture: PictureController<CustomerPicture, Customer>())

    persistable.resource("products", ProductController())
    persistable.picture(base: "products", slug: "products_id", picture: PictureController<ProductPicture, Product>())

    persistable.resource("questions", QuestionController())
    persistable.resource("campaigns", CampaignController())
    persistable.resource("answers", AnswerController())
    persistable.resource("orders", OrderController())
    persistable.resource("sections", SectionController())
    persistable.resource("customerAddresses", CustomerAddressController())
    persistable.resource("tags", TagController())

    StripeCollection().build(persistable)
    DescriptionCollection().build(persistable)
    
    persistable.get("search") { request in
        return try Product.makeQuery().all().map { $0.name }.makeResponse()
    }
}

do {
    try drop.run()
} catch {
    fatalError("Error while running droplet : \(error)")
}
