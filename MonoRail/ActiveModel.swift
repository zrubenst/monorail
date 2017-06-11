
import Foundation

open class ActiveModel:NSObject, Actionable, Awakable {
    
    /////////////////////////
    // Override This
    //
    /// Models should override this for customization
    open class func register() {
        
    }
    /////////////////////////
    /////////////////////////
    
    
    
    /////////////////////////
    // Functions to call in the register function
    
    public class func set(name:String, plural:String?=nil) {
        store.modelName = name
        if plural != nil {
            store.modelNamePlural = plural!
        } else {
            store.modelNamePlural = name.pluralize()
        }
    }
    
    public class func set(path:String) {
        var path = path
        if path.hasPrefix("/") { path.remove(at: path.startIndex) }
        if !path.hasSuffix("/") && !path.isEmpty { path += "/" }
        store.modelApiPath = path
    }
    
    public class func permit(actions:ActiveModel.Action...) { store.modelActions = actions }
    
    public class func json(root:String?, for action:ActiveModel.Action) { store.modelJsonRoot[action] = root }
    public class func set(serializer:ActiveSerializer?) { store.modelSerializer = serializer }
    public class func set(deserializer:ActiveDeserializer?) { store.modelDeserializer = deserializer }
    
    
    public enum CustomFieldType {
        case imbeds         // a model is imbeded within the response of this model
        case imbedsMany     // an array of imbeded models within the response of this model
        case references     // a field in this model's response references the ID of another model  |  can also act as a BelongTo kind of
        case referencesMany // a field in this model's response is an array of reference IDs of other models  |  very rare
        case has            // another model references this model
        case hasMany        // multiple other models reference this model
    }
    
    public struct CustomField<T:ActiveModel> {
        let type:CustomFieldType, model:T.Type, field:String,
        alias:String?, foreignField:String?
    }
    
    /////////////////////////
    /////////////////////////
    
    
    public enum Action {
        case create
        case get
        case getMany
        case update
        case delete
    }
    
    
    /////////////////////////
    // Exposing functions and model actions for protocols
    
    // Modellable
    private static var store:ActiveModel.Store { return ActiveModel.Store.from(self.self) }
    public static func modelActions() -> [ActiveModel.Action] { return store.modelActions }
    public static func modelApiPath() -> String { return store.modelApiPath }
    public static func modelName() -> String { return store.modelName }
    public static func modelNamePlural() -> String { return store.modelNamePlural }
    public func modelGetInstanceID() -> String { return className + "_" + id }
    public static func modelFieldNames() -> [String] { return fieldNames }
    public func modelGetThis() -> ActiveModel { return self }
    public static func modelGetNew() -> ActiveModel { return self.init() }
    public static func modelGetNewPersisted(id:String) -> ActiveModel { return self.init(id: id) }
    public func modelGetValue(forKey key:String) -> Any? { return self.value(forKeyPath:key) }
    public func modelSetValue(_ value:Any?, forKey key:String) { self.setValue(value, forKeyPath: key) }
    
    open override func setValue(_ value: Any?, forUndefinedKey key: String) {
        MonoRail.Error.warn(message: "Attempted to set a value for an undefined field '\(key)'", model: self)
    }
    
    open override func value(forUndefinedKey key: String) -> Any? {
        MonoRail.Error.warn(message: "Attempted to access an undefined field '\(key)'", model: self)
        return MonoRail.Error()
    }
    
    
    // Serializable
    public static func modelJsonRoot(action:ActiveModel.Action) -> String? { return store.modelJsonRoot[action] ?? nil }
    public static func customSerializer() -> ActiveSerializer? { return store.modelSerializer }
    public static func customDeserializer() -> ActiveDeserializer? { return store.modelDeserializer }
    public static func modelCustomFields() -> [ActiveModel.CustomField<ActiveModel>] { return store.modelCustomFields }
    
    // Defaults for stored values
    internal class func setStoreDefaults() {
        store.modelActions = [.get, .create, .update, .delete, .getMany]
        store.modelApiPath = ""
        store.modelName = className.lowercased()
        store.modelNamePlural = className.lowercased().pluralize()
        store.modelJsonRoot = [.get : store.modelName, .create : store.modelName,
                               .update : store.modelName, .delete : store.modelName,
                               .getMany : store.modelNamePlural]
    }
    
    /////////////////////////
    /////////////////////////
    
    
    
    /////////////////////////
    // Persistance
    
    private var _syncing = false
    var isSyncing:Bool { return _syncing }
    
    private func syncingBegan() {
        _syncing = true
    }
    
    private func syncingEnded() {
        _syncing = false
    }
    
    public func sync(from:ActiveModel) {
        
        if isArray { return }
        if isSyncing { return }
        syncingBegan()
        
        if !_isPersisted {
            _isPersisted = true
            addObservers()
        }
        
        if type(of: self) != type(of: self) {
            MonoRail.Error.warn(message: "Attempted to sync with a different instance of type \(from.self.className)", model: self.self)
            return
        }
        
        if id != from.id && !self.id.isEmpty {
            MonoRail.Error.warn(message: "Attempted to sync with differing IDs", model: self.self)
            return
        }
        
        if id.isEmpty {
            _id = from.id
        }
        
        for field in self.fieldNames {
            let value:Any? = from.modelGetValue(forKey: field)
            if value is MonoRail.Error {
                MonoRail.Error.warn(message: "Attempted to sync field '\(field)'", model: self.self)
                continue
            }
            self.modelSetValue(value, forKey: field)
        }
        
        syncingEnded()
    }
    
    private var _observerContext = 29
    private func addObservers() {
        if isArray { return }
        for field in self.fieldNames {
            self.addObserver(self, forKeyPath: field, options: [.new, .old], context: &_observerContext)
        }
        if _isPersisted { Persist.register(self) }
    }
    
    private func removeObservers() {
        if isArray { return }
        for field in self.fieldNames {
            self.removeObserver(self, forKeyPath: field, context: &_observerContext)
        }
        if _isPersisted { Persist.remove(self) }
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &_observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if isArray { return }
        if isSyncing { return }
        if keyPath == nil { return }
        let value = modelGetValue(forKey: keyPath!)
        if value is MonoRail.Error { return }
        
        if _isPersisted { Persist.push(synchronize: self) }
    }
    
    /////////////////////////
    /////////////////////////
    
    
    
    /////////////////////////
    // Instance functions and variables
    
    private var _isCreated:Bool = false
    public var modelCreated:Bool { return _isCreated }
    
    private var _isPersisted:Bool = false
    public var modelPersisted:Bool { return _isPersisted }
    
    private var _id:String = ""
    public var id:String { return _id }
    
    required override public init() {
        super.init()
        _isCreated = false
        _isPersisted = false
        addObservers()
    }
    
    required public init(id:String, persisted:Bool = true) {
        super.init()
        _id = id
        _isCreated = true
        _isPersisted = persisted
        if persisted {
            addObservers()
        } else if let friend = Persist.persisted(like: self) {
            sync(from: friend)
        }
    }
    
    deinit {
        removeObservers()
    }
    
    //////////////////////
    // Registerable
    
    public static var One:ActiveModel.Type {
        let type = self.self
        objc_setAssociatedObject(type, &activeModelTypeAssociatedHandle, "one", objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return type
    }
    
    public static var Many:ActiveModel.Type {
        let type = self.self
        objc_setAssociatedObject(type, &activeModelTypeAssociatedHandle, "many", objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return type
    }
    
    var registrationCustomField:Any?
    
    //////////////////////
    // Arrayable
    
    private var _isArray:Bool = false
    var isArray:Bool { return _isArray }
    
    required public init(persistedArray:Bool) {
        super.init()
        _isPersisted = persistedArray
        _isArray = true
    }
    
    public var _arrayCollection: NSArray = []
    public var _arrayCurrent: Int = 0
    
    
    //////////////////////
    // Awakable
    
    class func awake() {
        if store.modelActivated { return }
        setStoreDefaults()
        setupFieldTypes()
        register()
        store.modelActivated = true
    }
    
    private class func setupFieldTypes() {
        
        let model = modelGetNew()
        
        MonoRail.Error.turnOffErrors()
        
        print("\n" + model.className)
        print("-----------------")
        
        for field in model.fieldNames {
            
            let value = model.modelGetValue(forKey: field)
            
            if value is String {
                print("\(field): String or Enum")
            } else if value is Number {
                print("\(field): Number")
            } else if value is ActiveModel {
                
                guard let model = value as? ActiveModel else {
                    print("\(field): ActiveModel")
                    print("\t error")
                    continue
                }
                
                guard let custom:CustomField = model.registrationCustomField as? CustomField else {
                    print("\(field): ActiveModel")
                    print("\t error")
                    continue
                }
                
                print("\(field): \(custom.type)  to  \(custom.model.className)")
                print("\t alias:   \(String(describing: custom.alias))")
                print("\t foriegn: \(String(describing: custom.foreignField))")
                
            } else {
                print("\(field): Unknown")
            }
        }
        
        MonoRail.Error.turnOnErrors()
    }
    
    public enum RawFieldType { case string, number }
    public var fieldTypes:Dictionary<String, RawFieldType> { return type(of: self).fieldtypes }
    public static var fieldtypes:Dictionary<String, RawFieldType> { return store.modelFieldTypes }
    
}



