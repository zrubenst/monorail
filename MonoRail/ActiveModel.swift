
import Foundation

open class ActiveModel:NSObject, Actionable, Awakable {
    
    /////////////////////////
    /// Override this for customization of the Model
    open class func register() {
        
    }
    
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
    
    public enum Action {
        case create
        case get
        case getMany
        case update
        case delete
    }
    
    public enum CustomFieldType {
        case imbeds         // a model is imbeded within the response of this model
        case imbedsMany     // an array of imbeded models within the response of this model
        case references     // a field in this model's response references the ID of another model  |  can also act as a BelongTo kind of
        case referencesMany // a field in this model's response is an array of reference IDs of other models  |  very rare
        case has            // another model references this model
        case hasMany        // multiple other models reference this model
    }
    
    public class CustomField<T:ActiveModel> {
        let type:CustomFieldType
        let model:T.Type
        var field:String
        var alias:String?
        var foreignField:String?
        var inner:CustomField<T>?
        
        init(type:CustomFieldType, model:T.Type, field:String, alias:String?, foreignField:String?, inner:CustomField<T>?) {
            self.type = type
            self.model = model
            self.field = field
            self.alias = alias
            self.foreignField = foreignField
            self.inner = inner
        }
        
    }
    
    /////////////////////////
    /////////////////////////
    
    
    
    
    
    
    
    
    
    
    /////////////////////////
    // Protocol Exposing Functions
    
    private static var store:ActiveModel.Store { return ActiveModel.Store.from(self.self) }
    public static func modelActions() -> [ActiveModel.Action] { return store.modelActions }
    public static func modelApiPath() -> String { return store.modelApiPath }
    public static func modelName() -> String { return store.modelName }
    public static func modelNamePlural() -> String { return store.modelNamePlural }
    public func modelGetInstanceID() -> String { return className + "_" + id }
    public static func modelFieldNames() -> [String] { return fieldNames }
    public static func modelFieldTypes() -> Dictionary<String, ActiveModel.RawFieldType> { return fieldTypes }
    public func modelGetThis() -> ActiveModel { return self }
    public static func modelGetNew() -> ActiveModel { return self.init() }
    public static func modelGetNewPersisted(id:String) -> ActiveModel { return self.init(id: id) }
    public static func modelGetNewUnpersisted(id:String) -> ActiveModel { return self.init(id: id, persisted: false) }
    public func modelGetValue(forKey key:String) -> Any? { return self.value(forKeyPath:key) }
    public func modelSetValue(_ value:Any?, forKey key:String) { self.setValue(value, forKeyPath: key) }
    
    open override func setValue(_ value: Any?, forUndefinedKey key: String) {
        MonoRail.Error.warn(message: "Attempted to set a value for an undefined field '\(key)'", model: self)
    }
    
    open override func value(forUndefinedKey key: String) -> Any? {
        MonoRail.Error.warn(message: "Attempted to access an undefined field '\(key)'", model: self)
        return MonoRail.Error()
    }
    
    public static func modelJsonRoot(action:ActiveModel.Action) -> String? { return store.modelJsonRoot[action] ?? nil }
    public static func customSerializer() -> ActiveSerializer? { return store.modelSerializer }
    public static func customDeserializer() -> ActiveDeserializer? { return store.modelDeserializer }
    public static func modelCustomFields() -> [ActiveModel.CustomField<ActiveModel>] { return store.modelCustomFields }
    
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
    // Persistance (Syncing & Observers
    
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
        
        if !_isPersisted {
            _isPersisted = true
            addObservers()
        }
        
        syncingEnded()
    }
    
    private var _obseversAdded:Bool = false
    private var _observerContext = 29
    private func addObservers() {
        if isArray { return }

        for field in self.fieldNames {
            self.addObserver(self, forKeyPath: field, options: [.new, .old], context: &_observerContext)
        }
        _obseversAdded = true
        if _isPersisted { Persist.register(self) }
    }
    
    private func removeObservers() {
        if isArray { return }
        if !_obseversAdded { return }
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
    
    internal func persist() {
        _isPersisted = true
        _isCreated = true
        addObservers()
    }
    
    /////////////////////////
    /////////////////////////
    
    
    
    
    
    
    
    
    
    
    /////////////////////////
    // Instance variables and Basic Initializers
    
    private var _isCreated:Bool = false
    public var modelCreated:Bool { return _isCreated }
    
    internal var _isPersisted:Bool = false
    public var modelPersisted:Bool { return _isPersisted }
    
    private var _id:String = ""
    public var id:String { return _id }
    
    required override public init() {
        super.init()
        _isCreated = false
        _isPersisted = false
        resetFields()
    }
    
    required public init(id:String, persisted:Bool = true) {
        super.init()
        _id = id
        _isCreated = true
        _isPersisted = persisted
        resetFields()
        if persisted {
            addObservers()
        } else if let friend = Persist.persisted(like: self) {
            sync(from: friend)
        }
    }
    
    deinit {
        removeObservers()
    }

    /////////////////////////
    /////////////////////////
    
    
    
    
    
    
    
    
    
    
    //////////////////////
    // Scoped Initializers
    
    
    ////////////
    // Arrayable
    
    required public init(persistedArray:Bool) {
        super.init()
        _isPersisted = persistedArray
        _isArray = true
        
    }
    
    required public init(models:Array<ActiveModel>, persisted:Bool = true) {
        super.init()
        _isPersisted = persisted
        _isArray = true
        _arrayCollection = models as NSArray
        resetFields()
    }
    
    //////
    //////
    
    
    ////////////
    // Registerable
    
    public required init(resetFields:Bool) {
        super.init()
        _isArray = true
        if resetFields { self.resetFields() }
    }
    
    //////
    //////
    
    
    ////////////
    // Belonging
    
    public required init(referencesId foreignId:String, foreignKey:String) {
        super.init()
        _belongs = true
        _isPersisted = false
        _isCreated = false
        _belongingForeignID = foreignId
        _belongingForeignKey = foreignKey
    }
    
    public required init(manyReferenceId foreignId:String, foreignKey:String) {
        super.init()
        _belongs = true
        _isArray = true
        _isPersisted = false
        _isCreated = false
        _belongingForeignID = foreignId
        _belongingForeignKey = foreignKey
    }
    
    //////
    //////
    
    
    /////////////////////////
    /////////////////////////
    
    

    
    
    
    
    
    
    //////////////////////
    // Arrayable
    
    private var _isArray:Bool = false
    var isArray:Bool { return _isArray }
    
    public var _arrayCollection: NSArray = []
    public var _arrayCurrent: Int = 0
    
    /////////////////////////
    /////////////////////////
    
    
    
    
    
    
    
    
    
    
    //////////////////////
    // Awakable
    
    class func awake() {
        if store.modelActivated { return }
        setStoreDefaults()
        setupFieldTypes()
        register()
        store.modelActivated = true
    }
    
    /////////////////////////
    /////////////////////////
    
    
    
    
    
    
    
    
    
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
    
    private func resetFields() {
        if self.fieldNames.contains("_isPersisted") { return }
        
        MonoRail.Error.turnOffErrors()
        
        for field in fieldNames {
            modelSetValue(nil, forKey: field)
        }
        
        MonoRail.Error.turnOnErrors()
    }
    
    private class func setupFieldTypes() {
        if fieldNames.contains("_isPersisted") { return }
        
        MonoRail.Error.turnOffErrors()
        
        let model = self.init(resetFields: false)
        var fieldTypes = Dictionary<String, RawFieldType>()
        
        for field in model.fieldNames {
            
            let value = model.modelGetValue(forKey: field)
            
            if value is String {
                fieldTypes[field] = .string
            } else if value is Number {
                fieldTypes[field] = .number
            } else if value is ActiveModel {
                
                guard let model = value as? ActiveModel else {
                    continue
                }
                
                guard let custom:CustomField = model.registrationCustomField as? CustomField else {
                    continue
                }
                
                fieldTypes[field] = .relation
                
                custom.field = field.snakeCased.lowercased()
                
                if custom.alias == nil {
                    if custom.type == .references {
                        custom.alias = field.snakeCased.lowercased() + "_id"
                    } else {
                        custom.alias = field.snakeCased.lowercased()
                    }
                }
                
                if custom.foreignField == nil {
                    custom.foreignField = field.snakeCased.lowercased() + "_id"
                }
                
                if custom.inner != nil {
                    custom.inner!.field = field
                    
                    if custom.inner!.alias == nil {
                        if custom.inner!.type == .references {
                            custom.inner!.alias = field.snakeCased.lowercased() + "_id"
                        } else {
                            custom.inner!.alias = field.snakeCased.lowercased()
                        }
                    }
                    
                    if custom.inner!.foreignField == nil {
                        custom.inner!.foreignField = field.snakeCased.lowercased() + "_id"
                    }
                }
                
                store.modelCustomFields.append(custom)
                
            } else {
                continue
            }
        }
        
        store.modelFieldTypes = fieldTypes
        MonoRail.Error.turnOnErrors()
    }
    
    public enum RawFieldType { case string, number, relation }
    public static var fieldTypes:Dictionary<String, RawFieldType> { return store.modelFieldTypes }
    
    /////////////////////////
    /////////////////////////
    
    
    
    
    
    
    
    
    
    //////////////////////
    // Belonging
    
    private var _belongs:Bool = false
    var modelBelongs:Bool { return _belongs }
    
    private var _belongingForeignKey:String?
    var modelBelongingForeignKey:String? { return _belongingForeignKey }
    
    private var _belongingForeignID:String?
    var modelBelongingForeignId:String? { return _belongingForeignID }
    
    /////////////////////////
    /////////////////////////
    
    
    
    
    
    
    
    
    
    /////////////////////////
    // Helpers
    
    public func printOut(_ prefix:String = "", level:Int = 0, maxLevel:Int = 3) {
        
        if _isPersisted == false {
            print(prefix + "\(self.className) (\(self.id))")
            print(prefix + "\tNot Persisted")
            return
        }
        
        if level > maxLevel {
            if self.isArray {
                print(prefix + "\(self.className) []")
            } else {
                print(prefix + "\(self.className) (\(self.id))")
            }
            
            print(prefix + "\tPersisted")
            return
        }
        
        if _isArray {
            print(prefix + "\(self.className) []")
            for model in _arrayCollection as! Array<ActiveModel> {
                model.printOut(prefix + "\t", level: level + 1, maxLevel: maxLevel)
            }
            return
        }
        
        
        if level == 0 { print("--------------------") }
        print(prefix + "\(self.className) (\(self.id))")
        
        for field in self.fieldNames {
            
            let value = self.modelGetValue(forKey: field)
            
            if value == nil {
                print(prefix + "\t\(field):\n\(prefix)\t\tnil")
                continue
            }
            
            if value is ActiveModel {
                print(prefix + "\t\(field):  -->")
                
                (value as! ActiveModel).printOut(prefix + "\t\t", level: level + 1, maxLevel: maxLevel)
                continue
            }
            
            print(prefix + "\t\(field):\n\(prefix)\t\t\(value!)")
        }
    }
    
    /////////////////////////
    /////////////////////////
    
    
}



