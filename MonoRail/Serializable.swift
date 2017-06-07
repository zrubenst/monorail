
import Foundation

public protocol Serializable: Modellable {

}

internal extension Serializable {
    
    internal static func serialize(model:Self) -> Dictionary<String, Any> {
        return Dictionary<String, Any>()
    }
    
    internal static func deserialize(data:NSDictionary) -> Self {
        return modelGetNew() as! Self
    }
    
    internal static func deserialize(data:Dictionary<String, Any>) -> Self {
        return deserialize(data: data as NSDictionary)
    }
    
}
