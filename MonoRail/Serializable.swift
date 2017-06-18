
import Foundation

public protocol Serializable: Modellable {
    static func modelJsonRoot(action:ActiveModel.Action) -> String?
    static func customDeserialize(dictionary: NSDictionary) -> Self?
    static func customSerialize(model:ActiveModel, action:ActiveModel.Action?) -> Dictionary<String, Any?>?
    static func modelCustomFields() -> [ActiveModel.CustomField]
}

public extension Serializable {

    
    public static func serialize(model:Self, action:ActiveModel.Action? = nil) -> Dictionary<String, Any?>? {
        
        guard let model = model as? ActiveModel else { return nil }
        
        if let customDictionary:Dictionary<String, Any?> = customSerialize(model: model, action: action) {
            return customDictionary
        }
        
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
                if !related.isCreated { continue }
                
                let key = custom.imbedded ? custom.foreignField! : custom.alias!
                
                dict[key] = related.id
                continue
            }
            
            if custom.type == .referencesMany {
                guard let relatedMany:ActiveModel = model.modelGetValue(forKey: field) as? ActiveModel else { continue }
                if !relatedMany.isArray { continue }
                
                let relatedArray = relatedMany._arrayCollection
                var relatedIds:Array<String> = []
                
                for related:ActiveModel in relatedArray {
                    if !related.isCreated { continue }
                    relatedIds.append(related.id)
                }
                
                let key = custom.imbedded ? custom.foreignField! : custom.alias!
                
                dict[key] = relatedIds
                continue
            }
            
        }
        
        return dict
    }
    
    public static func deserialize(response:Dictionary<String, Any?>, action:ActiveModel.Action) -> Self? {
        return deserialize(response: response as NSDictionary, action: action)
    }
    
    public static func deserialize(response:NSDictionary, action:ActiveModel.Action) -> Self? {
        
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
    
    public static func deserializeMany(data:NSDictionary) -> [Self]? {
        guard let root:String = modelJsonRoot(action: .getMany) else { return nil }
        guard let dataArray:NSArray = data[root] as? NSArray else { return nil }
        var array:Array<Self> = []
        
        for dataElement in dataArray {
            guard let dict:NSDictionary = dataElement as? NSDictionary else { return nil }
            guard let model:Self = deserialize(data: dict) else { return nil }
            
            array.append(model)
        }
        
        return array
    }
    
    public static func deserialize(data:NSDictionary, imbedded:Bool = false) -> Self? {
        // important note. Imbedded in this context means that the current data is imbedded within another model's response
        
        if let customModel:Self = customDeserialize(dictionary: data) {
            return customModel
        }
        
        guard let id:String = extractId(data["id"]) else { return nil }

        let model = imbedded ? modelGetNewUnpersisted(id: id) : modelGetNewPersisted(id: id)
        
        let fields = model.fieldNames
        let scheme = customScheme()
        
        
        for field:String in fields {
                        
            guard let custom:ActiveModel.CustomField = scheme[field] else {
                safelySet(model: model, field: field, to: data[field.snakeCased])
                continue
            }
            
            if imbedded {
                setCustomField(model: model, field: field, data: data, custom: custom, imbedded: false)
            } else {
                setCustomField(model: model, field: field, data: data, custom: custom, imbedded: custom.imbedded)
            }
            
        }
        
        if imbedded {
            model.persist()
        } else {
            model.modelWasUpdated()
        }
        
        return model as? Self
    }
    
}

//////////////////////
// Helpers

public extension Serializable {
    
    static func setCustomField(model:ActiveModel, field:String, data:NSDictionary, custom:ActiveModel.CustomField, imbedded:Bool = false) {
        // important note. Imbedded in this context is a flag for whether or not the data should be treated as imbedded
        
        if custom.type == .references && !imbedded {
            guard let referenceId:String = extractId(data[custom.foreignField!]) else {
                return
            }
            let referenceModel = custom.model.modelGetNewUnpersisted(id: referenceId)  //init(id: referenceId, persisted: false)
            safelySet(model: model, field: field, to: referenceModel)
            return
        }
        
        if custom.type == .referencesMany && !imbedded {
            guard let referenceArray:NSArray = data[custom.alias!] as? NSArray else { return }
            
            var referencesModels = Array<ActiveModel>()
            
            for idData in referenceArray {
                guard let id:String = extractId(idData) else { continue }
                
                let referenceModel = custom.model.modelGetNewUnpersisted(id: id)  //init(id: id, persisted: false)
                referencesModels.append(referenceModel)
            }
            
            let manyModel = custom.model.init(models: referencesModels, persisted: true)
            
            safelySet(model: model, field: field, to: manyModel)
            return
        }
        
        if custom.type == .has && !imbedded {
            
            if let currentReference:ActiveModel = model.value(forKey: field) as? ActiveModel {
                if currentReference.isPersisted { return }
            }
            
            let belongsTo = custom.model.init(referencesId: model.id, foreignKey: custom.foreignField!)
            safelySet(model: model, field: field, to: belongsTo)
            
            return
        }
        
        if custom.type == .hasMany && !imbedded {
            
            if let currentReference:ActiveModel = model.value(forKey: field) as? ActiveModel {
                if currentReference.isPersisted { return }
            }
            
            let belongsToMany = custom.model.init(manyReferenceId: model.id, foreignKey: custom.foreignField!)
            safelySet(model: model, field: field, to: belongsToMany)
            
            return
        }
        
        if (custom.type == .references || custom.type == .has) && imbedded {
            guard let imbedData:NSDictionary = data[custom.alias!] as? NSDictionary else { return }
            guard let imbeddedModel = custom.model.deserialize(data: imbedData, imbedded: true) else { return }
            
            safelySet(model: model, field: field, to: imbeddedModel)
            return
        }
        
        if (custom.type == .referencesMany || custom.type == .hasMany) && imbedded {
            
            guard let imbedArray:Array<NSDictionary> = data[custom.alias!] as? Array<NSDictionary> else { return }
            
            var models = Array<ActiveModel>()
            
            for imbedData:NSDictionary in imbedArray {
                guard let imbeddedModel = custom.model.deserialize(data: imbedData, imbedded: true) else {
                    return
                }
                models.append(imbeddedModel)
            }
            
            let manyModel = custom.model.init(models: models, persisted: true)
            
            safelySet(model: model, field: field, to: manyModel)
            return
        }
        
    }
    
    static func deserialize(data:Dictionary<String, Any?>) -> Self? {
        return deserialize(data: data as NSDictionary)
    }
    
    static internal func customScheme() -> [String : ActiveModel.CustomField] {
        
        var scheme:[String : ActiveModel.CustomField] = [:] as! [String : ActiveModel.CustomField]
        
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
        } else if type == .dictionary && value is NSDictionary {
            val = value
        } else if type == .array && value is NSArray {
            val = value
        } else if type == .date && value is String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            val = formatter.date(from: value as! String)
        }  else {
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














