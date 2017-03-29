//
//  StripeError.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/19/17.
//
//

public enum StripeError: Error {
    
    case error(type: String, message: String)
    
    public var localizedDescription: String {
        switch self {
        case let .error(type, message):
            return "<StripeError> \(type) : \(message)"
        }
    }
}
