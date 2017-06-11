
import Foundation


public protocol ActiveReference: Arrayable {

}

public extension ActiveReference {
    public func ignore(_ m: Self) { }
}



/// ReferencesOne: A reference to an ID of another model is present
/// ReferencesMany: Uncommon. An array of references to another model by ID is present
public func References<T:ActiveModel>(_ type:T.Type, aliasing:String? = nil) -> Optional<T> {
    
    let modelType = objc_getAssociatedObject(type, &activeModelTypeAssociatedHandle) as! String
    let customType:ActiveModel.CustomFieldType = (modelType == "many") ? .referencesMany : .references
    let custom = ActiveModel.CustomField(type: customType, model: type, field: "", alias: aliasing, foreignField: nil)
    let model = T()
    model.registrationCustomField = custom
    return Optional.some(model)
}


/// ImbedsOne: Another model is embeded in the response for this model
/// ImbedsMany: An array of other models is embedded in the response for this model
public func Imbeds<T:ActiveModel>(_ type:T.Type, aliasing:String? = nil) -> Optional<T> {
    
    let modelType = objc_getAssociatedObject(type, &activeModelTypeAssociatedHandle) as! String
    let customType:ActiveModel.CustomFieldType = (modelType == "many") ? .imbedsMany : .imbeds
    
    let custom = ActiveModel.CustomField(type: customType, model: type, field: "", alias: aliasing, foreignField: nil)
    let model = T()
    model.registrationCustomField = custom
    return Optional.some(model)
}


/// HasOne/HasMany: No reference is made, an API lookup for this models foreign key is required
public func Has<T:ActiveModel>(_ type:T.Type, foreignKey:String? = nil) -> Optional<T> {
    
    let modelType = objc_getAssociatedObject(type, &activeModelTypeAssociatedHandle) as! String
    let customType:ActiveModel.CustomFieldType = (modelType == "many") ? .hasMany : .has
    
    let custom = ActiveModel.CustomField(type: customType, model: type, field: "", alias: nil, foreignField: foreignKey)
    let model = T()
    model.registrationCustomField = custom
    return Optional.some(model)
}

/// BelongsTo: Has a reference to a single model  |  alias for ReferencesOne
/// BelongsToMany: An array of models reference this model  |  alias for HasMany
public func BelongsTo<T:ActiveModel>(_ type:T.Type, foreignKey:String? = nil) -> Optional<T> {
    
    let modelType = objc_getAssociatedObject(type, &activeModelTypeAssociatedHandle) as! String
    let customType:ActiveModel.CustomFieldType = (modelType == "many") ? .hasMany : .references
    
    let custom = ActiveModel.CustomField(type: customType, model: type, field: "", alias: nil, foreignField: foreignKey)
    let model = T()
    model.registrationCustomField = custom
    return Optional.some(model)
}
