
import Foundation

public protocol Modellable {
    
    static func modelActions() -> [ActiveModel.Action]
    static func modelApiPath() -> String
    static func modelName() -> String
    static func modelNamePlural() -> String
    
    static func modelFieldNames() -> [String]
    func modelGetValue(forKey key:String) -> Any?
    func modelSetValue(_ value:Any?, forKey key:String)
    
    func modelGetThis() -> ActiveModel
    static func modelGetNew() -> ActiveModel
    static func modelGetNewPersisted(id:String) -> ActiveModel
    
    static func assertActivatedModel()
    
}

extension Modellable {
    
    static func asSelf(instance:Any) -> Self? {
        if let me:Self = instance as? Self {
            return me
        }
        return nil
    }
    
    func asSelf(instance:Any) -> Self? {
        if let me:Self = instance as? Self {
            return me
        }
        return nil
    }
    
}
