
import Foundation

open class ActiveModel:NSObject, Actionable {
    
    /////////////////////////
    // Override This
    //
    /// Models should override this for customization
    open class func register() {
        
    }
    /////////////////////////
    /////////////////////////
    
    
    
    /////////////////////////
    // Functions to call in the activate function
    
    public class func set(name:String, plural:String?=nil) {
        store.modelName = name
        if plural != nil {
            store.modelNamePlural = plural!
        } else {
            store.modelNamePlural = name.pluralize()
        }
    }
    
    public class func set( path:String) {
        var path = path
        if path.hasPrefix("/") { path.remove(at: path.startIndex) }
        if !path.hasSuffix("/") && !path.isEmpty { path += "/" }
        store.modelApiPath = path
    }
    
    /// Pass ActiveModel.Actions that this Model can perform.
    /// Options: create, get, getMany, update, delete
    public class func permit(actions:ActiveModel.Action...) {
        store.modelActions = actions
    }
    
    
    /// Usage: has(<Model>.self, atField: #keyPath(<instance variable>))
    public class func has<T:ActiveModel>(_ model:T.Type, atField:String) {
        
    }
    
    public class func has<T:ActiveModel>(many model:T.Type, atField:String) {
        
    }
    
    public class func has<T:ActiveModel>(_ model:T.Type, action:ActiveModel.Action, payload:Dictionary<String, String>) {
        
    }
    
    public class func belongs<T:ActiveModel>(to model:T.Type, foreignField:String) {
        
    }
    
    public class func belongs<T:ActiveModel>(to model:T.Type, action:ActiveModel.Action, payload:Dictionary<String, String>) {
        
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
    // Modellable and Registration functions

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
    public static func assertActivatedModel() {
        if store.modelActivated { return }
        setStoreDefaults()
        register()
        store.modelActivated = true
    }
    
    open override func setValue(_ value: Any?, forUndefinedKey key: String) {
        Active.Error.warn(message: "Attempted to set a value for an undefined field '\(key)'", model: self)
    }
    
    open override func value(forUndefinedKey key: String) -> Any? {
        Active.Error.warn(message: "Attempted to access an undefined field '\(key)'", model: self)
        return Active.Error()
    }
    
    internal class func setStoreDefaults() {
        store.modelActions = [.get, .create, .update, .delete, .getMany]
        store.modelApiPath = ""
        store.modelName = className.lowercased()
        store.modelNamePlural = className.lowercased().pluralize()
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
        
        if isSyncing { return }
        syncingBegan()
        
        if type(of: self) != type(of: self) {
            Active.Error.warn(message: "Attempted to sync with a different instance of type \(from.self.className)", model: self.self)
            return
        }
        
        if id != from.id && !self.id.isEmpty && !from.id.isEmpty {
            Active.Error.warn(message: "Attempted to sync with differing IDs", model: self.self)
            return
        }
        
        for field in self.fieldNames {
            let value:Any? = from.modelGetValue(forKey: field)
            if value is Active.Error {
                Active.Error.warn(message: "Attempted to sync field '\(field)'", model: self.self)
                continue
            }
            self.modelSetValue(value, forKey: field)
        }
        
        syncingEnded()
    }
    
    private var _observerContext = 29
    private func addObservers() {
        for field in self.fieldNames {
            self.addObserver(self, forKeyPath: field, options: [.new, .old], context: &_observerContext)
        }
        Persist.register(self)
    }
    
    private func removeObservers() {
        for field in self.fieldNames {
            self.removeObserver(self, forKeyPath: field, context: &_observerContext)
        }
        Persist.remove(self)
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &_observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if isSyncing { return }
        if keyPath == nil { return }
        let value = modelGetValue(forKey: keyPath!)
        if value is Active.Error { return }
        
        Persist.push(synchronize: self)
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
    
    required public init(deserialize dict:Dictionary<String, Any>) {
        super.init()
        _isCreated = true
        _isPersisted = true
        addObservers()
    }
    
    required public init(id:String) {
        super.init()
        _id = id
        _isCreated = true
        _isPersisted = true
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
}























