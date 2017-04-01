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
import Auth

let drop = Droplet.create()

let appendQuery = ["managed": true, "email": "hakon@hanesand.no", "country": "US", "legal_entity[type]": "company", "metadata[id]": "28"] as [String : CustomStringConvertible]
var query = ""

guard !appendQuery.isEmpty else {
    fatalError("error")
}

let test = appendQuery
    .map { key, value in
        return "\(key)=\(value)"
    }
    .joined(separator: "&")

var new = ""

new += query
new += "&"

new += test
query = new

print("New query : \(query)")

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

drop.collection(StripeCollection.self)
drop.collection(AuthenticationCollection())

drop.run()
