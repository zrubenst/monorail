
import Foundation


public protocol ActiveReference: Arrayable {

}

public extension ActiveReference {
    public func ignore(_ m: Self) { }
}



/// ReferencesOne: A reference to an ID of another model is present
/// ReferencesMany: Uncommon. An array of references to another model by ID is present
public func References<T:ActiveModel>(_ type:T.Type, aliasing:String? = nil, referenceIdField:String?=nil) -> Optional<T> {
    
    let modelType = objc_getAssociatedObject(type, &activeModelTypeAssociatedHandle) as! String
    let imbedsType = objc_getAssociatedObject(type, &activeModelImbedsAssociatedHandle) as! String
    let imbedded = imbedsType == "imbedded"
    let customType:ActiveModel.CustomFieldType = (modelType == "many") ? .referencesMany : .references
    
    let custom = ActiveModel.CustomField(type: customType, model: type, field: "", alias: aliasing, foreignField: referenceIdField, imbedded: imbedded)
    let model = T()
    model.registrationCustomField = custom
    return Optional.some(model)
}

/// HasOne/HasMany: No reference is made, an API lookup for this models foreign key is required
public func Has<T:ActiveModel>(_ type:T.Type, aliasing:String? = nil, foreignKey:String? = nil) -> Optional<T> {
    
    let modelType = objc_getAssociatedObject(type, &activeModelTypeAssociatedHandle) as! String
    let imbedsType = objc_getAssociatedObject(type, &activeModelImbedsAssociatedHandle) as! String
    let imbedded = imbedsType == "imbedded"
    let customType:ActiveModel.CustomFieldType = (modelType == "many") ? .hasMany : .has
    
    let custom = ActiveModel.CustomField(type: customType, model: type, field: "", alias: aliasing, foreignField: foreignKey, imbedded: imbedded)
    custom.imbedded = imbedsType == "imbedded"
    let model = T()
    model.registrationCustomField = custom
    return Optional.some(model)
}

/// BelongsTo: Is referenced by a single other model  |  alias for HasOne
/// BelongsToMany: An array of models reference this model  |  alias for HasMany
public func BelongsTo<T:ActiveModel>(_ type:T.Type, aliasing:String? = nil, foreignKey:String? = nil) -> Optional<T> {
    
    let modelType = objc_getAssociatedObject(type, &activeModelTypeAssociatedHandle) as! String
    let imbedsType = objc_getAssociatedObject(type, &activeModelImbedsAssociatedHandle) as! String
    let imbedded = imbedsType == "imbedded"
    let customType:ActiveModel.CustomFieldType = (modelType == "many") ? .hasMany : .has
    
    let custom = ActiveModel.CustomField(type: customType, model: type, field: "", alias: aliasing, foreignField: foreignKey, imbedded: imbedded)
    custom.imbedded = imbedsType == "imbedded"
    let model = T()
    model.registrationCustomField = custom
    return Optional.some(model)
}



/// ImbedsOne: Another model is embeded in the response for this model
/// ImbedsMany: An array of other models is embedded in the response for this model
//public func Imbeds<T:ActiveModel>(_ type:T.Type, aliasing:String? = nil, referenceIdField:String?=nil, whenImbeded: Optional<T>? = nil) -> Optional<T> {
//
//    let modelType = objc_getAssociatedObject(type, &activeModelTypeAssociatedHandle) as! String
//    let customType:ActiveModel.CustomFieldType = (modelType == "many") ? .imbedsMany : .imbeds
//
//    var inner:ActiveModel.CustomField<T>? = nil
//
//    if let imbedded:ActiveModel = whenImbeded as? ActiveModel {
//        if let custom:ActiveModel.CustomField<T> = imbedded.registrationCustomField as? ActiveModel.CustomField<T> {
//            inner = custom
//        }
//    }
//
//    let custom = ActiveModel.CustomField(type: customType, model: type, field: "", alias: aliasing, foreignField: referenceIdField, inner: inner)
//    let model = T()
//    model.registrationCustomField = custom
//    return Optional.some(model)
//}



