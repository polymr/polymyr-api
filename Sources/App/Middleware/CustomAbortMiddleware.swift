//
//  CustomAbortMiddleware.swift
//  subber-api
//
//  Created by Hakon Hanesand on 12/1/16.
//
//

import Vapor
import HTTP
import Foundation

class CustomAbortMiddleware: Middleware {
    public func respond(to request: Request, chainingTo chain: Responder) throws -> Response {
        do {
            return try chain.respond(to: request)
        } catch Abort.badRequest {
            return try CustomAbortMiddleware.errorResponse(request, .badRequest, "Invalid request")
        } catch Abort.notFound {
            return try CustomAbortMiddleware.errorResponse(request, .notFound, "Page not found")
        } catch Abort.serverError {
            return try CustomAbortMiddleware.errorResponse(request, .internalServerError, "Something went wrong")
        } catch Abort.custom(let status, let message) {
            return try CustomAbortMiddleware.errorResponse(request, status, message)
        } catch {
            drop.console.error("\(error)")
            return try CustomAbortMiddleware.errorResponse(request, .internalServerError, "Error \(error)")
        }
    }
    
    static func errorResponse(_ request: Request, _ status: Status, _ message: String) throws -> Response {
        
        let json = try JSON(node: ["error": true, "message": "\(message)" ])
        let response = try Response(status: status, body: .data(json.makeBytes()))
        response.headers["Content-Type"] = "application/json; charset=utf-8"
        
        if status == .forbidden || status == .unauthorized {
            response.headers["WWW-Authenticate"] = "Basic"
        }
        
        return response
    }
}
