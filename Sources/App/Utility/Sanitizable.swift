import Vapor

/// A request-extractable `Model`.
public protocol Sanitizable {
    /// Fields that are permitted to be deserialized from a Request's JSON.
    static var permitted: [String] { get }
}
