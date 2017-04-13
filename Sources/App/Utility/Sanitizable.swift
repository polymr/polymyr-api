import Vapor

/// A request-extractable `Model`.
public protocol Sanitizable {
    /// Fields that are permitted to be deserialized from a Request's JSON.
    static var permitted: [String] { get }
    
    /// Validate all deserialized fields.
    func postValidate() throws
}

extension Sanitizable {
    
    public static func preValidate(data: JSON) throws {
        
    }
    
    public func postValidate() throws {
        
    }
}
