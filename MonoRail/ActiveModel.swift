
import Foundation

open class ActiveModel:NSObject, Actionable, Awakable {
    
    /////////////////////////
    /// Override these for customization of the Model
    
    
    open class func register() {
        
    }
    
    
    open class func customDeserialize(dictionary:NSDictionary) -> Self? {
        return nil
    }
    
    open class func customSerialize(model:ActiveModel, action:ActiveModel.Action? = nil) -> Dictionary<String, Any?>? {
        return nil
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
    
    public enum Action {
        case create
        case get
        case getMany
        case update
        case delete
    }
    
    public enum CustomFieldType {
        case references     // a field in this model's response references the ID of another model  |  can also act as a BelongTo kind of
        case referencesMany // a field in this model's response is an array of reference IDs of other models  |  very rare
        case has            // another model references this model
        case hasMany        // multiple other models reference this model
    }
    
    public class CustomField {
        let type:CustomFieldType
        let model:ActiveModel.Type
        var field:String = ""
        var alias:String?
        var foreignField:String?
        var inverseOf:String?
        var imbedded:Bool
        
        init(type:CustomFieldType, model:ActiveModel.Type, field:String, alias:String?, foreignField:String?, inverseOf:String?=nil, imbedded:Bool) {
            self.type = type
            self.model = model
            self.field = field
            self.alias = alias
            self.foreignField = foreignField
            self.inverseOf = inverseOf
            self.imbedded = imbedded
        }
        
    }
    
    /////////////////////////
    /////////////////////////
    
    
    
    
    
    
    
    
    
    
    /////////////////////////
    // Protocol Exposing Functions
    
    internal static var store:ActiveModel.Store { return ActiveModel.Store.from(self.self) }
    public static func modelActions() -> [ActiveModel.Action] { return store.modelActions }
    public static func modelApiPath() -> String { return store.modelApiPath }
    public static func modelName() -> String { return store.modelName }
    public static func modelNamePlural() -> String { return store.modelNamePlural }
    public func modelGetInstanceID() -> String { return className + "_" + id }
    public static func modelFieldNames() -> [String] { return fieldNames }
    public static func modelFieldTypes() -> Dictionary<String, ActiveModel.RawFieldType> { return fieldTypes }
    public func modelGetThis() -> ActiveModel { return self }
    public static func modelGetNew() -> ActiveModel { return self.init() }
    public static func modelGetNewPersisted(id:String) -> ActiveModel {
        guard let persisted = Persist.persisted(className: className, id: id) else { return self.init(id: id) }
        return persisted
    }
    public static func modelGetNewUnpersisted(id:String) -> ActiveModel {
        guard let persisted = Persist.persisted(className: className, id: id) else { return self.init(id: id, persisted: false) }
        return persisted
    }
    public func modelGetValue(forKey key:String) -> Any? { return self.value(forKeyPath:key) }
    public func modelSetValue(_ value:Any?, forKey key:String) { self.setValue(value, forKeyPath: key) }
    
    open override func setValue(_ value: Any?, forUndefinedKey key: String) {
        MonoRail.Error.warn(message: "Attempted to set a value for an undefined field '\(key)'", model: self)
    }
    
    open override func value(forUndefinedKey key: String) -> Any? {
        MonoRail.Error.warn(message: "Attempted to access an undefined field '\(key)'", model: self)
        return MonoRail.Error()
    }
    
    public static func modelJsonRoot(action:ActiveModel.Action) -> String? { return store.modelJsonRoot == nil ? nil : action == .getMany ? store.modelJsonRoot!.pluralize() : store.modelJsonRoot  }
    public static func modelCustomFields() -> [ActiveModel.CustomField] { return store.modelCustomFields }
    public func modelCustomFields() -> [ActiveModel.CustomField] { return type(of: self).modelCustomFields() }
    
    internal class func setStoreDefaults() {
        store.modelActions = [.get, .create, .update, .delete, .getMany]
        store.modelApiPath = ""
        store.modelName = className.lowercased()
        store.modelNamePlural = className.lowercased().pluralize()
        store.modelJsonRoot = store.modelName
    }
    
    /////////////////////////
    /////////////////////////
    
    
    
    
    
    
    
    
    
    
    /////////////////////////
    // Persistance (Updating, Syncing & Observers)
    
    public func modelWasUpdated() {
        Persist.push(synchronize: self)
    }
    
    private var _syncing = false
    internal var isSyncing:Bool { return _syncing }
    
    private func syncingBegan() {
        _syncing = true
    }
    
    private func syncingEnded() {
        _syncing = false
    }
    
    @discardableResult
    public func sync(from:ActiveModel) -> Bool {
        
        if isArray { return false }
        if isSyncing { return false }
        syncingBegan()
        
        if type(of: self) != type(of: self) {
            MonoRail.Error.warn(message: "Attempted to sync with a different instance of type \(from.self.className)", model: self.self)
            return false
        }
        
        if id != from.id && !self.id.isEmpty {
            MonoRail.Error.warn(message: "Attempted to sync with differing IDs", model: self.self)
            return false
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
        }
        
        syncingEnded()
        return true
    }
    
    internal func persist() {
        _isPersisted = true
        _isCreated = true
        Persist.push(synchronize: self)
    }
    
    internal func destroy() {
        _isPersisted = false
        _isCreated = false
        _id = ""
        resetFields()
        Persist.remove(self)
    }
    
    /////////////////////////
    /////////////////////////
    
    
    
    
    
    
    
    
    
    
    /////////////////////////
    // Instance variables and Basic Initializers
    
    private var _isCreated:Bool = false
    public var isCreated:Bool { return _isCreated }
    
    internal var _isPersisted:Bool = false
    public var isPersisted:Bool { return _isPersisted }
    
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
        if !persisted, let friend = Persist.persisted(like: self) {
            sync(from: friend)
        }
        Persist.register(self)
    }
    
    convenience public init(id:Int, persist:Bool = true) {
        self.init(id: "\(id)", persisted: persist)
    }
    
    deinit {
        Persist.remove(self)
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
        _arrayCollection = models
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
    public var isArray:Bool { return _isArray }
    
    public var _arrayCollection:Array<ActiveModel> = Array<ActiveModel>()
    public var _arrayCurrent:Int = 0
    
    public func count() -> Int {
        return _arrayCollection.count
    }
    
    public func contains(_ model:ActiveModel) -> Bool {
        
        for m in _arrayCollection {
            if m.same(as: model) { return true }
        }
        
        return false
    }
    
    internal func set(new models:[ActiveModel]) {
        if !isArray { return }
        
        _arrayCollection = models
        
    }
    
    public func add(_ model:ActiveModel) {
        if !_isArray || _belongs { return }
        
        _arrayCollection.append(model)
    }
    
    public func remove(_ model:ActiveModel) {
        if !_isArray || _belongs { return }
        
        for instance in _arrayCollection {
            if instance.same(as: model) {
                _arrayCollection.remove(object: instance)
            }
        }
    }
    
    internal func forceAdd(_ model:ActiveModel) {
        if !_isArray { return }
        _arrayCollection.append(model)
    }
    
    internal func forceRemove(_ model:ActiveModel) {
        if !_isArray { return }
        
        for instance in _arrayCollection {
            if instance.same(as: model) {
                _arrayCollection.remove(object: instance)
            }
        }
    }
    
    /////////////////////////
    /////////////////////////
    
    
    
    
    
    
    
    
    
    
    //////////////////////
    // Awakable
    
    class func awake() {
        if store.modelActivated { return }
        setStoreDefaults()
        setupFieldTypes()
        register()
        Persist.register(model: self)
        store.modelActivated = true
    }
    
    /////////////////////////
    /////////////////////////
    
    
    
    
    
    
    
    
    
    //////////////////////
    // Registerable
    
    internal var _registrationCustomField:Any?
    
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
                
        let model = self.init(resetFields: false)
        var fieldTypes = Dictionary<String, RawFieldType>()
        
        for field in model.fieldNames {
            
            guard let custom = store.modelRegistrationFields[field] else {
                let value = model.modelGetValue(forKey: field)
                
                if value is String {
                    fieldTypes[field] = .string
                } else if value is Number {
                    fieldTypes[field] = .number
                } else if value is NSDictionary {
                    fieldTypes[field] = .dictionary
                } else if value is NSArray {
                    fieldTypes[field] = .array
                } else if value is Date {
                    fieldTypes[field] = .date
                }
                
                continue
            }
                
            fieldTypes[field] = .relation
            
            custom.field = field.snakeCased.lowercased()
            
            
            if custom.imbedded {
                
                if custom.alias == nil {
                    // alias points to the root of the imbed/imbedMany
                    if custom.type == .references || custom.type == .has {
                        custom.alias = field.snakeCased.lowercased()
                    } else {
                        custom.alias = field.snakeCased.lowercased()
                    }
                }
                
                if custom.foreignField == nil {
                    if custom.type == .references {
                        custom.foreignField = custom.alias! + "_id" // foreign field (referenceIdField) here points to the field with the reference ID
                    } else if custom.type == .referencesMany {
                        custom.foreignField = custom.alias! // foreign field (referenceIdField) here points to the root of the array of reference IDs
                    }
                }
                
            } else {
                if custom.alias == nil {
                    if custom.type == .references {
                        custom.alias = field.snakeCased.lowercased() + "_id"
                    } else if custom.type == .referencesMany {
                        custom.alias = field.snakeCased.lowercased()
                    }
                }
                
                if custom.foreignField == nil {
                    if custom.type == .references {
                        custom.foreignField = custom.alias!// foreign field (referenceIdField) here points to the field with the reference ID
                    } else if custom.type == .referencesMany {
                        custom.foreignField = custom.alias! // foreign field (referenceIdField) here points to the root of the array of reference IDs
                    }
                }
            }
            
            
            // if the type is a Has/HasMany...
            // foreign field is the foreign key that makes reference to this model from the other model
            if custom.foreignField == nil && (custom.type == .has || custom.type == .hasMany) {
                custom.foreignField = className.snakeCased.lowercased() + "_id"
            }
            
            store.modelCustomFields.append(custom)
        }
        
        store.modelFieldTypes = fieldTypes
    }
    
    public enum RawFieldType { case string, number, relation, dictionary, array, date }
    public static var fieldTypes:Dictionary<String, RawFieldType> { return store.modelFieldTypes }
    
    /////////////////////////
    /////////////////////////
    
    
    
    
    
    
    
    
    //////////////////////
    // Relationships
    
    public func same(as other:ActiveModel) -> Bool {
        return self.id == other.id && self._isPersisted && other.className == self.className
    }
    
    internal func references(_ other:ActiveModel) -> Bool {
        
        if isArray {
            return self.contains(other)
        }
        
        return same(as: other)
    }
    
    internal func backwardsReference(field:String, reference:ActiveModel) {
        
        if let value:ActiveModel = self.modelGetValue(forKey: field) as? ActiveModel {
            if value.isArray {
                value.forceAdd(reference)
                return
            }
        }
        
        self.modelSetValue(reference, forKey: field)
    }
    
    internal func dereference(field:String, reference:ActiveModel) {
        
        if let value:ActiveModel = self.modelGetValue(forKey: field) as? ActiveModel {
            if value.isArray {
                value.forceRemove(reference)
                return
            }
        }
        
        self.modelSetValue(nil, forKey: field)
    }

    /////////////////////////
    /////////////////////////
    
    
    
    
    
    
    
    
    //////////////////////
    // Belonging
    
    private var _belongs:Bool = false
    internal var modelBelongs:Bool { return _belongs }
    
    private var _belongingForeignKey:String?
    internal var modelBelongingForeignKey:String? { return _belongingForeignKey }
    
    private var _belongingForeignID:String?
    internal var modelBelongingForeignId:String? { return _belongingForeignID }
    
    /////////////////////////
    /////////////////////////
    
    
    
    
    
    
    
    
    
    /////////////////////////
    // Helpers
    
    public func printOut(_ prefix:String = "", level:Int = 0, maxLevel:Int = 3) {
        
        if _isPersisted == false {
            if _isArray {
                print(prefix + "\(self.className) []")
            } else {
                print(prefix + "\(self.className) (\(self.id))")
            }
            
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
            if !_isPersisted {
                print(prefix + "\tNot Persisted")
                return
            }
            if _arrayCollection.count <= 0 {
                print(prefix + "\tPersisted (empty)")
                return
            }
            for model in _arrayCollection {
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



