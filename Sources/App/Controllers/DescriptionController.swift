//
//  DescriptionController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/19/17.
//
//

import Foundation
import HTTP
import Vapor
import Fluent

fileprivate func handle(upload request: Request, for product: Int) throws -> String {
    guard let data = request.formData?.first?.value.part.body else {
        throw Abort.custom(status: .badRequest, message: "No file in request")
    }
    
    return try save(data: Data(bytes: data), for: product)
}

func save(data: Data, for product: Int) throws -> String {
    
    let descriptionFolder = "Public/descriptions"
    
    guard let workPath = Droplet.instance?.workDir else {
        throw Abort.custom(status: .internalServerError, message: "Missing working directory")
    }
    
    let saveURL = URL(fileURLWithPath: workPath).appendingPathComponent(descriptionFolder, isDirectory: true).appendingPathComponent("\(product).json", isDirectory: false)
    
    do {
        try data.write(to: saveURL)
    } catch {
        throw Abort.custom(status: .internalServerError, message: "Unable to write multipart form data to file. Underlying error \(error)")
    }
    
    return "https://static.polymyr.com/descriptions/\(product).json"
}

final class DescriptionController: ResourceRepresentable {
    
    func show(_ request: Request, product: Int) throws -> ResponseRepresentable {
        return "https://static.polymyr.com/descriptions/\(product)"
    }
    
    func modify(_ request: Request, product: Int) throws -> ResponseRepresentable {
        return try handle(upload: request, for: product)
    }
    
    func makeResource() -> Resource<Int> {
        return Resource(
            show: show,
            modify: modify
        )
    }
}
