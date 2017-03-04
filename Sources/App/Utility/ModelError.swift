//
//  ModelError.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Foundation
import Vapor

enum ModelError: Error, CustomStringConvertible {
    
    case missingLink(from: Model.Type, to: Model.Type, id: Int?)
    case ownerMismatch(from: Model.Type, to: Model.Type, fromId: Int?, toId: Int?)
    
    var description: String {
        switch self {
        case let .missingLink(from, to, id):
            return "Missing relation from \(from) to \(to) with foreign id \(id ?? 0)."
        case let .ownerMismatch(from, to, fromId, toId):
            return "The object on \(to) linked from \(from) is not owned by the \(from)'s #\(fromId ?? 0). It is owned by \(toId ?? 0)"
        }
    }
}
