
import Foundation

public protocol Serializable: Modellable {
    static func modelJsonRoot(action:ActiveModel.Action) -> String?
    static func customSerializer() -> ActiveSerializer?
    static func customDeserializer() -> ActiveDeserializer?
    static func modelCustomFields() -> [ActiveModel.CustomField<ActiveModel>]
}

public extension Serializable {
    
    
    
    
    public static func serialize(model:Self, action:ActiveModel.Action? = nil) -> Dictionary<String, Any?>? {
        
        guard let model = model as? ActiveModel else { return nil }
        
        let types = modelFieldTypes()
        let scheme = customScheme()
        
        var dict:Dictionary<String, Any> = [:]
        
        for field in model.fieldNames {
            
            guard let type:ActiveModel.RawFieldType = types[field] else { continue }
            
            if type == .string {
                dict[field.snakeCased] = model.modelGetValue(forKey: field) as? String
                continue
            } else if type == .number {
                dict[field.snakeCased] = model.modelGetValue(forKey: field) as? Number
                continue
            }
            
            guard let custom:ActiveModel.CustomField = scheme[field] else { continue }
            
            if custom.type == .has || custom.type == .hasMany { continue }
            
            if custom.type == .references {
                guard let related:ActiveModel = model.modelGetValue(forKey: field) as? ActiveModel else { continue }
                
                dict[custom.alias!] = related.id
                continue
            }
            
            if custom.type == .referencesMany {
                guard let relatedMany:ActiveModel = model.modelGetValue(forKey: field) as? ActiveModel else { continue }
                if !relatedMany.isArray { continue }
                guard let relatedArray:Array<ActiveModel> = relatedMany._arrayCollection as? Array<ActiveModel> else { continue }
                
                var relatedIds:Array<String> = []
                
                for related:ActiveModel in relatedArray {
                    relatedIds.append(related.id)
                }
                
                dict[custom.alias!] = relatedIds
                continue
            }
            
            if custom.type == .imbeds {
                guard let related:ActiveModel = model.modelGetValue(forKey: field) as? ActiveModel else { continue }
                
                dict[custom.foreignField!] = related.id
                continue
            }
            
            if custom.type == .imbedsMany {
                guard let relatedMany:ActiveModel = model.modelGetValue(forKey: field) as? ActiveModel else { continue }
                if !relatedMany.isArray { continue }
                guard let relatedArray:Array<ActiveModel> = relatedMany._arrayCollection as? Array<ActiveModel> else { continue }
                
                var relatedIds:Array<String> = []
                
                for related:ActiveModel in relatedArray {
                    relatedIds.append(related.id)
                }
                
                dict[custom.alias!] = relatedIds
                continue
            }
            
        }
        
        if action == nil || modelJsonRoot(action: action!) == nil { return dict }
        
        let root = modelJsonRoot(action: action!)!
        
        return [root : dict]
    }
    
    public static func deserialzie(response:Dictionary<String, Any?>, action:ActiveModel.Action) -> Self? {
        return deserialzie(response: response as NSDictionary, action: action)
    }
    
    public static func deserialzie(response:NSDictionary, action:ActiveModel.Action) -> Self? {
        
        var data:NSDictionary = response
        
        if modelJsonRoot(action: action) != nil {
            if let modelData:NSDictionary = data[modelJsonRoot(action: action)!] as? NSDictionary {
                data = modelData
            } else {
                return nil
            }
        }
        
        return deserialize(data: data)
    }
    
    public static func deserialize(data:NSDictionary, imbedded:Bool = false) -> Self? {
        
        guard let id:String = extractId(data["id"]) else { return nil }

        let model = imbedded ? modelGetNewUnpersisted(id: id) : modelGetNewPersisted(id: id)
        let fields = model.fieldNames
        let scheme = customScheme()
        
        
        for field:String in fields {
            
            guard var custom:ActiveModel.CustomField = scheme[field] else {
                safelySet(model: model, field: field, to: data[field])
                continue
            }
            
            if imbedded && custom.inner != nil {
                setCustomField(model: model, field: field, data: data, custom: custom.inner!, imbeded: imbedded)
            } else {
                setCustomField(model: model, field: field, data: data, custom: custom, imbeded: imbedded)
            }
    
        }
        
        if imbedded {
            model.persist()
        }
        
        return model as? Self
    }
    
}

//////////////////////
// Helpers

public extension Serializable {
    
    static func setCustomField(model:ActiveModel, field:String, data:NSDictionary, custom:ActiveModel.CustomField<ActiveModel>, imbeded:Bool = false) {
        
        if custom.type == .references {
            guard let referenceId:String = extractId(data[custom.alias!]) else { return }
            let referenceModel = custom.model.init(id: referenceId, persisted: false)
            safelySet(model: model, field: field, to: referenceModel)
            return
        }
        
        if custom.type == .referencesMany {
            guard let referenceArray:NSArray = data[custom.alias!] as? NSArray else { return }
            
            var referencesModels = Array<ActiveModel>()
            
            for idData in referenceArray {
                guard let id:String = extractId(idData) else { continue }
                
                let referenceModel = custom.model.init(id: id, persisted: false)
                referencesModels.append(referenceModel)
            }
            
            let manyModel = custom.model.init(models: referencesModels, persisted: true)
            
            safelySet(model: model, field: field, to: manyModel)
            return
        }
        
        if custom.type == .imbeds {
            guard let imbedData:NSDictionary = data[custom.alias!] as? NSDictionary else { return }
            guard let imbededModel = custom.model.deserialize(data: imbedData, imbedded: true) else { return }
            
            safelySet(model: model, field: field, to: imbededModel)
            return
        }
        
        if custom.type == .imbedsMany {
            
            guard let imbedArray:Array<NSDictionary> = data[custom.alias!] as? Array<NSDictionary> else { return }
            
            var models = Array<ActiveModel>()
            
            for imbedData:NSDictionary in imbedArray {
                guard let imbededModel = custom.model.deserialize(data: imbedData, imbedded: true) else {
                    return
                }
                models.append(imbededModel)
            }
            
            let manyModel = custom.model.init(models: models, persisted: true)
            
            safelySet(model: model, field: field, to: manyModel)
            return
        }
        
        if custom.type == .has {
            
            let belongsTo = custom.model.init(referencesId: model.id, foreignKey: custom.foreignField!)
            safelySet(model: model, field: field, to: belongsTo)
            
            return
        }
        
        if custom.type == .hasMany {
            
            let belongsToMany = custom.model.init(manyReferenceId: model.id, foreignKey: custom.foreignField!)
            safelySet(model: model, field: field, to: belongsToMany)
            
            return
        }
        
    }
    
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
        
        let type = modelFieldTypes()[field]
        var val:Any? = nil
        
        if type == .string && value is String {
            val = value as! String
        } else if type == .number && value is Number {
            val = value as! Number
        } else if type == .relation && value is ActiveModel {
            val = value
        } else {
            return
        }
        
        model.modelSetValue(val, forKey: field)
    }
    
    internal static func extractId(_ id:Any?) -> String? {
        if let id_num:NSNumber = id as? NSNumber {
            return id_num.stringValue
        } else if let id_str:String = id as? String {
            return id_str
        }
        return nil
    }
}














