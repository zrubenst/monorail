
import Foundation

public protocol Serializable: Modellable {
    static func modelJsonRoot(action:ActiveModel.Action) -> String?
    static func customSerializer() -> ActiveSerializer?
    static func customDeserializer() -> ActiveDeserializer?
    static func modelCustomFields() -> [ActiveModel.CustomField<ActiveModel>]
}

public extension Serializable {
    
    public static func serialize(model:Self) -> Dictionary<String, Any?> {
        return Dictionary<String, Any?>()
    }
    
    
    public static func deserialize(data:NSDictionary) -> Self? {
        
        guard let id:String = extractId(data: data) else { return nil }
        
        let model = modelGetNewPersisted(id: id)
        let fields = model.fieldNames
        let scheme = customScheme()
        
        for field:String in fields {
            
            guard let custom:ActiveModel.CustomField = scheme[field] else {
                if data.allKeys.contains(where: { $0 as? String == field }) {
                    safelySet(model: model, field: field, to: data[field])
                }
                continue
            }
            
        }
        
        return model as? Self
    }
    
}

//////////////////////
// Helpers

public extension Serializable {
    
    static func deserialize(data:Dictionary<String, Any?>) -> Self? {
        return deserialize(data: data as NSDictionary)
    }
    
    static internal func customScheme() -> [String : ActiveModel.CustomField<ActiveModel>] {
        
        var scheme:[String : ActiveModel.CustomField<ActiveModel>] = [:] as! [String : ActiveModel.CustomField<ActiveModel>]
        
        for custom in modelCustomFields() {
            scheme[custom.field] = custom
        }
        
        return scheme
    }
    
    static internal func safelySet(model: ActiveModel, field:String, to value:Any?) {
        
        if !(value == nil || value is String || value is NSString || value is NSNumber) { return }
        
        var val:Any? = nil
        
//        if value
        
    }
    
    internal static func extractId(data:NSDictionary) -> String? {
        if let id_num:NSNumber = data["id"] as? NSNumber {
            return id_num.stringValue
        } else if let id_str:String = data["id"] as? String {
            return id_str
        }
        return nil
    }
}














