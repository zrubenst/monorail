
import Foundation

public protocol Actionable: Serializable {
    func modelWasUpdated()
}

public extension Actionable {
    
    /////////////////////
    // Fetch
    
    func fetch(success: @escaping ()->Void, failure:((ActiveNetworkError)->Void)? = nil) {
        let this = self.this
        
        if !this.isCreated && !this.isArray {
            failure?(ActiveNetworkError(error: NSError(domain: "fetch can only be called on 'Many' models and created models", code: 422), dict: nil))
            return
        }
        
        if this.isArray && !this.modelBelongs {
            failure?(ActiveNetworkError(error: NSError(domain: "fetching a references many is not currently allowed", code: 422), dict: nil))
            return
        }
        
        if this.modelBelongs, let foreign:String = this.modelBelongingForeignKey, let foreignId = this.modelBelongingForeignId {
            Self.get(where: [foreign:foreignId], success: { (models:[Self]) in
                
                if this.isArray {
                    this.set(new: models as! [ActiveModel])
                    this._isPersisted = true
                } else if models.count > 0 {
                    if !self.this.sync(from: models.first! as! ActiveModel) {
                        failure?(Self.genericError)
                        return
                    }
                    return
                }
                
                failure?(Self.genericError)
                return
                
            }, failure: failure)
        }
        
        if this.id == "" {
            failure?(ActiveNetworkError(error: NSError(domain: "error fetching", code: 422), dict: nil))
            return
        }
        
        Self.get(id: this.id, success: { (model:Self) in
            
            if !self.this.sync(from: model.this) {
                failure?(Self.genericError)
                return
            }
            
            self.this.persist()
            
            success()
            
        }, failure: failure)
        
    }
    
    @discardableResult
    func fetch() -> Bool {
        let this = self.this
        
        if !this.isCreated && !this.isArray { return false }
        if this.isArray && !this.modelBelongs { return false }
        
        if this.modelBelongs, let foreign:String = this.modelBelongingForeignKey, let foreignId = this.modelBelongingForeignId {
            
            guard let models = Self.get(where: [foreign:foreignId]) else { return false }
            
            if this.isArray {
                this.set(new: models as! [ActiveModel])
                this._isPersisted = true
            } else if models.count > 0 {
                if !self.this.sync(from: models.first! as! ActiveModel) { return false }
                
                return true
            }
            
            return false
        }
        
        if this.id == "" {
            return false
        }
        
        guard let model = Self.get(id: this.id) else { return false }
        
        if !self.this.sync(from: model.this) { return false }
        
        self.this.persist()
        return true
    }

    
    /////////////////////
    // GET
    
    public static func get(id:String, success: @escaping (Self)->Void, failure:((ActiveNetworkError)->Void)? = nil) {
        let url = MonoRail.apiRootUrl + "/" + Self.modelApiPath() + Self.modelNamePlural() + "/" + id
        call(.get, url: url, success: success, failure: failure)
    }
    
    public static func get(id:String) -> Self? {
        let url = MonoRail.apiRootUrl + "/" + Self.modelApiPath() + Self.modelNamePlural() + "/" + id
        return call(.get, url: url)
    }
    
    public static func get(id:Int, success: @escaping (Self)->Void, failure:((ActiveNetworkError)->Void)? = nil) {
        get(id: "\(id)", success: success, failure: failure)
    }
    
    public static func get(id:Int) -> Self? {
        return get(id: "\(id)")
    }
    
    public static func get(where params:Dictionary<String, Any?> = [:], success: @escaping ([Self])->Void, failure:((ActiveNetworkError)->Void)? = nil) {
        let url = MonoRail.apiRootUrl + "/" + Self.modelApiPath() + Self.modelNamePlural()

        ActiveNetwork.call(.get, url: url, parameters: params, success: { (dict:Dictionary<String, Any?>) in
            
            guard let models = deserializeMany(data: dict as NSDictionary) else {
                failure?(genericError)
                return
            }
            
            success(models)
            
        }, failure: { (error:ActiveNetworkError) in
            failure?(error)
        })
    }
    
    public static func get(where params:Dictionary<String, Any?> = [:]) -> [Self]? {
        let url = MonoRail.apiRootUrl + "/" + Self.modelApiPath() + Self.modelNamePlural()
        
        let response:ActiveNetworkResponse = ActiveNetwork.call(.get, url: url, parameters: params)
        if response.error != nil || response.data == nil { return nil }
        
        guard let models = deserializeMany(data: response.data! as NSDictionary) else {
            return nil
        }
        
        return models
    }
    
    
    /////////////////////
    // CREATE
    
    func create(success: @escaping ()->Void, failure:((ActiveNetworkError)->Void)? = nil) {
        let url = MonoRail.apiRootUrl + "/" + Self.modelApiPath() + Self.modelNamePlural()
        let params = Self.serialize(model: self)
        
        Self.call(.post, url: url, parameters: params, success: { (model:Self) in
            
            if !self.this.sync(from: model.this) {
                failure?(Self.genericError)
                return
            }
            
            self.this.persist()
            
            success()
            
        }, failure: failure)
    }
    
    @discardableResult
    func create() -> Bool {
        let url = MonoRail.apiRootUrl + "/" + Self.modelApiPath() + Self.modelNamePlural()
        let params = Self.serialize(model: self)
        
        guard let model:Self = Self.call(.post, url: url, parameters: params) else { return false }
        if !self.this.sync(from: model.this) { return false }
        self.this.persist()
        return true
    }
    
    
    /////////////////////
    // SAVE
    
    func save(success: @escaping ()->Void, failure:((ActiveNetworkError)->Void)? = nil) {
        if !self.this.isCreated {
            create(success: success, failure: failure)
            return
        }
        
        let url = MonoRail.apiRootUrl + "/" + Self.modelApiPath() + Self.modelNamePlural() + "/" + self.this.id
        let params = Self.serialize(model: self)
        
        Self.call(.put, url: url, parameters: params, success: { (model:Self) in
            
            if !self.this.sync(from: model.this) {
                failure?(Self.genericError)
                return
            }
            
            self.this.persist()
            
            success()
            
        }, failure: failure)
    }
    
    @discardableResult
    func save() -> Bool {
        if !self.this.isCreated { return create() }
        
        let url = MonoRail.apiRootUrl + "/" + Self.modelApiPath() + Self.modelNamePlural() + "/" + self.this.id
        let params = Self.serialize(model: self)
        
        guard let model:Self = Self.call(.put, url: url, parameters: params) else { return false }
        if !self.this.sync(from: model.this) { return false }
        self.this.persist()
        return true
    }
    
    
    /////////////////////
    // DELETE
    
    func delete(success: @escaping ()->Void, failure:((ActiveNetworkError)->Void)? = nil) {
        let url = MonoRail.apiRootUrl + "/" + Self.modelApiPath() + Self.modelNamePlural() + "/" + self.this.id
        
        ActiveNetwork.call(.delete, url: url, success: { (dict:Dictionary<String, Any?>) in
            
            Persist.destroy(self.this)
            
            self.this.destroy()
            
            success()
            
        }, failure: failure)
        
    }
    
    @discardableResult
    func delete() -> Bool {
        let url = MonoRail.apiRootUrl + "/" + Self.modelApiPath() + Self.modelNamePlural() + "/" + self.this.id
        
        if ActiveNetwork.call(.delete, url: url).error != nil { return false }
        Persist.destroy(self.this)
        self.this.destroy()
        if self.this.isPersisted || self.this.isCreated { return false }
        return true
    }
    
}


//////////////////
// Helpers

public extension Actionable {
    
    internal static var genericError:ActiveNetworkError { return ActiveNetworkError(error: NSError(domain: "An error occurred", code: 422, userInfo: nil), dict: nil) }
    
    internal static func call(_ action:NetworkVerb, url:String, parameters:Dictionary<String, Any?>? = nil, success: @escaping (Self)->Void, failure: ((ActiveNetworkError)->Void)?) {
        
        ActiveNetwork.call(action, url: url, parameters: parameters, success: { (dict:Dictionary<String, Any?>) in
            
            guard let model = deserialize(response: dict, action: .get) else {
                failure?(genericError)
                return
            }
            
            success(model)
            
        }, failure: { (error:ActiveNetworkError) in
            failure?(error)
        })
    }
    
    internal static func call(_ action:NetworkVerb, url:String, parameters:Dictionary<String, Any?>? = nil) -> Self? {
        
        let response:ActiveNetworkResponse = ActiveNetwork.call(action, url: url, parameters: parameters)
        
        if response.error != nil || response.data == nil { return nil }
        
        guard let model = deserialize(response: response.data!, action: .get) else {
            return nil
        }
        
        return model
    }
}



