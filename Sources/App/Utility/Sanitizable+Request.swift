import HTTP
import Node
import Vapor
import FluentProvider

extension Request {

    public func extractModel<M: Model>() throws -> M where M: Sanitizable {
        return try extractModel(injecting: .null)
    }

    public func extractModel<M: Model>(injecting values: Node) throws -> M where M: Sanitizable {
        guard let json = self.json else {
            throw Abort.badRequest
        }
        
        var sanitized = json.permit(M.permitted)
        values.object?.forEach { key, value in
            sanitized[key] = JSON(value)
        }
        
        try M.preValidate(data: sanitized)
        
        let model: M
        do {
            model = try M(node: sanitized)
        } catch {
            let error = M.updateThrownError(error)
            throw error
        }
        
        try model.postValidate()
        return model
    }

    public func patchModel<M: Model>(id: NodeRepresentable) throws -> M where M: Sanitizable {
        guard let model = try M.find(id) else {
            throw Abort.notFound
        }
        
        return try patchModel(model)
    }

    public func patchModel<M: Model>(_ model: M) throws -> M where M: Sanitizable {
        // consider making multiple lines
        guard let requestJSON = self.json?.permit(M.permitted).makeNode(in: emptyContext).object else {
            throw Abort.badRequest
        }
        
        var modelJSON = try model.makeNode(in: emptyContext)
        
        requestJSON.forEach {
            modelJSON[$0.key] = $0.value
        }
        
        var model: M
        do {
            model = try M(node: modelJSON)
        } catch {
            let error = M.updateThrownError(error)
            throw error
        }
        
        model.exists = true
        try model.postValidate()
        return model
    }
}
