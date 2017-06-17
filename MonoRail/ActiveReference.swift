
import Foundation


public protocol ActiveReference: Arrayable {

}

public extension ActiveReference {
    public func ignore(_ m: Self) { }
    
    public static var One:Self.Type {
        let type = self.self
        objc_setAssociatedObject(type, &activeModelTypeAssociatedHandle, "one", objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(type, &activeModelImbedsAssociatedHandle, "not_imbedded", objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return type
    }
    
    public static var Many:Self.Type {
        let type = self.self
        objc_setAssociatedObject(type, &activeModelTypeAssociatedHandle, "many", objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(type, &activeModelImbedsAssociatedHandle, "not_imbedded", objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return type
    }
    
    public static var ImbedsOne:Self.Type {
        let type = self.self
        objc_setAssociatedObject(type, &activeModelTypeAssociatedHandle, "one", objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(type, &activeModelImbedsAssociatedHandle, "imbedded", objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return type
    }
    
    public static var ImbedsMany:Self.Type {
        let type = self.self
        objc_setAssociatedObject(type, &activeModelTypeAssociatedHandle, "many", objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(type, &activeModelImbedsAssociatedHandle, "imbedded", objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return type
    }
}



/// ReferencesOne: A reference to an ID of another model is present
/// ReferencesMany: Uncommon. An array of references to another model by ID is present
/// * at: the name of the instance variable in the model object. Defaults to "relatedModel" or "relatedModels"
/// * aliasing: the name of the field in the JSON response. Defaults to the name of the variable and adds an "_id" if it is a non-embedded single reference
/// * referenceIdField: the name of the id field that this field will serialize to. Will use the alias and the relationship type default to "related_model_id" or "related_models"
/// * inverseOf: the name of the variable (in another model class) that relates to this model
public func References<T:ActiveModel>(_ type:T.Type, at:String? = nil, aliasing:String? = nil, referenceIdField:String?=nil, inverseOf:String?=nil) -> Optional<T> {
    
    if MonoRail.Registration.active {
        
        guard let parent = parentModel() else { return Optional<T>(nilLiteral: ()) }
        let modelType = objc_getAssociatedObject(type, &activeModelTypeAssociatedHandle) as! String
        let imbedsType = objc_getAssociatedObject(type, &activeModelImbedsAssociatedHandle) as! String
        let imbedded = imbedsType == "imbedded"
        let customType:ActiveModel.CustomFieldType = (modelType == "many") ? .referencesMany : .references
        let field:String = at != nil ? at! : customType == .referencesMany ? type.className.camelCased.pluralize() : type.className.camelCased
    
        let custom = ActiveModel.CustomField(type: customType, model: type, field: field, alias: aliasing, foreignField: referenceIdField,
                                         inverseOf: inverseOf,  imbedded: imbedded)
    
        parent.store.modelRegistrationFields[field] = custom
    }

    return Optional<T>(nilLiteral: ())
}

/// HasOne/HasMany: No reference is made, an API lookup with this models foreign key is required
/// * at: the name of the instance variable in the model object. Defaults to "relatedModel" or "relatedModels"
/// * aliasing: the name of the field in the JSON response. Is not used unless the related model is imbedded! Defaults to the name of the variable
/// * foerignKey: the name of the foreign key of this model in the related model (the name used in the api). Defaults to the name of the class of the given type, adding "_id" or pluralizing when appropriate
public func Has<T:ActiveModel>(_ type:T.Type, at:String? = nil, aliasing:String? = nil, foreignKey:String? = nil) -> Optional<T> {
    
    if MonoRail.Registration.active {
        
        guard let parent = parentModel() else { return Optional<T>(nilLiteral: ()) }
        let modelType = objc_getAssociatedObject(type, &activeModelTypeAssociatedHandle) as! String
        let imbedsType = objc_getAssociatedObject(type, &activeModelImbedsAssociatedHandle) as! String
        let imbedded = imbedsType == "imbedded"
        let customType:ActiveModel.CustomFieldType = (modelType == "many") ? .hasMany : .has
        let field:String = at != nil ? at! : customType == .hasMany ? type.className.camelCased.pluralize() : type.className.camelCased
        
        let custom = ActiveModel.CustomField(type: customType, model: type, field: field, alias: aliasing, foreignField: foreignKey, imbedded: imbedded)
        
        parent.store.modelRegistrationFields[field] = custom
    }
    
    return Optional<T>(nilLiteral: ())
}

internal func parentModel() -> ActiveModel.Type? {
    
    let sourceString:String = Thread.callStackSymbols[2]
    let separatorSet:CharacterSet = CharacterSet(charactersIn: " -[]+?.,")
    let array = NSMutableArray(array: sourceString.components(separatedBy: separatorSet))
    array.remove("")
    
    guard let framework = array[1] as? String, let string = array[3] as? String else { return nil }
    guard var start = string.endIndex(of: framework), let end = string.index(of: "cfT") else { return nil }
    start = string.index(after: start)
    
    let className = string.substring(with: start..<end)

    guard let namespace = Bundle.main.infoDictionary?[kCFBundleExecutableKey as String] as? String else { return nil }
    guard let type:AnyClass = NSClassFromString("\(namespace).\(className)") else { return nil }
    
    guard let model:ActiveModel.Type = type as? ActiveModel.Type else { return nil }
    
    return model
}

func stringClassFromString(_ className: String) -> AnyClass! {
    
    /// get namespace
    let namespace = Bundle.main.infoDictionary!["CFBundleExecutable"] as! String;
    
    /// get 'anyClass' with classname and namespace
    let cls: AnyClass = NSClassFromString("\(namespace).\(className)")!;
    
    // return AnyClass!
    return cls;
}


/// BelongsTo is an alias for Has
/// * at: the name of the instance variable in the model object. Defaults to "relatedModel" or "relatedModels"
/// * aliasing: the name of the field in the JSON response. Is not used unless the related model is imbedded! Defaults to the name of the variable
/// * foerignKey: the name of the foreign key of this model in the related model (the name used in the api). Defaults to the name of the class of the given type, adding "_id" or pluralizing when appropriate
public func BelongsTo<T:ActiveModel>(_ type:T.Type, at:String? = nil, aliasing:String? = nil, foreignKey:String? = nil) -> Optional<T> {
   return Has(type, at: at, aliasing: aliasing, foreignKey: foreignKey)
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



