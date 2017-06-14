
import Foundation

public protocol Actionable: Serializable {
    func modelWasUpdated()
}

public extension Actionable {
    
    public func save(success:(()->Void)? = nil, failure:((NSError)->Void)? = nil) {
        
//        let url = Active.apiRootUrl + "/" + Self.modelApiPath() + Self.modelNamePlural()
        
    }
    
    public static func get(id:String, success: @escaping (Self)->Void, failure:((NSError)->Void)? = nil) {
        let url = MonoRail.apiRootUrl + "/" + Self.modelApiPath() + Self.modelNamePlural() + "/" + id
        call(.get, url: url, success: success, failure: failure)
    }
    
    public static func get(id:String) -> Self? {
        let url = MonoRail.apiRootUrl + "/" + Self.modelApiPath() + Self.modelNamePlural() + "/" + id
        return call(.get, url: url)
    }
    
    public static func get(id:Int, success: @escaping (Self)->Void, failure:((NSError)->Void)? = nil) {
        get(id: "\(id)", success: success, failure: failure)
    }
    
    public static func get(id:Int) -> Self? {
        return get(id: "\(id)")
    }
    
}


//////////////////
// Helpers

public extension Actionable {
    
    internal static var genericError:NSError { return NSError(domain: "An error occurred", code: 422, userInfo: nil) }
    
    internal static func call(_ action:NetworkVerb, url:String, success: @escaping (Self)->Void, failure: ((NSError)->Void)?) {
        
        ActiveNetwork.call(action, url: url, success: { (dict:Dictionary<String, Any?>) in
            
            guard let model = deserialzie(response: dict, action: .get) else {
                failure?(genericError)
                return
            }
            
            success(model)
            
        }, failure: { (error:NSError, data:Data?) in failure?(error) })
        
    }
    
    internal static func call(_ action:NetworkVerb, url:String) -> Self? {
        
        let response:ActiveNetworkResponse = ActiveNetwork.call(action, url: url)
        
        if response.error != nil || response.data == nil { return nil }
        
        guard let model = deserialzie(response: response.data!, action: .get) else {
            return nil
        }
        
        return model
    }
}



