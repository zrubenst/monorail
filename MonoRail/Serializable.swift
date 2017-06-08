
import Foundation

public protocol Serializable: Modellable {

}

public extension Serializable {
    
    public static func serialize(model:Self) -> Dictionary<String, Any?> {
        return Dictionary<String, Any?>()
    }
    
    public static func deserialize(data:NSDictionary) -> Self? {
        
        var id:String = ""
        
        if let id_num:NSNumber = data["id"] as? NSNumber {
            id = id_num.stringValue
        } else if let id_str:String = data["id"] as? String {
            id = id_str
        } else {
            return nil
        }
        
        let model = modelGetNewPersisted(id: id)
        
        let fields = model.fieldNames
        
        for field:String in fields {
            let value = data[field]
            model.modelSetValue(value, forKey: field)
        }
        
        return model as? Self
    }
    
    static func deserialize(data:Dictionary<String, Any?>) -> Self? {
        return deserialize(data: data as NSDictionary)
    }
    
}
