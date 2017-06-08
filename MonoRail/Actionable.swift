
import Foundation

public protocol Actionable: Serializable {
    
}

public extension Actionable {
    
    internal static var error:NSError { return NSError(domain: "An error occurred", code: 422, userInfo: nil) }
    
    internal func call() {
        
    }
    
    
    public func save(success:(()->Void)? = nil, failure:((NSError)->Void)? = nil) {
        
//        let url = Active.apiRootUrl + "/" + Self.modelApiPath() + Self.modelNamePlural()
        
    }
    
    public static func get(id:String, success: @escaping (Self)->Void, failure:((NSError)->Void)? = nil) {
       
        let url = Active.apiRootUrl + "/" + Self.modelApiPath() + Self.modelNamePlural() + "/" + id
        
        ActiveNetwork.call(.get, url: url, success: { (dict:Dictionary<String, Any?>) in
            
            guard let data:Dictionary<String, Any?> = dict[modelName()] as? Dictionary<String, Any?> else {
                failure?(error)
                return
            }
            
            guard let model = deserialize(data: data) else {
                failure?(error)
                return
            }
            
            success(model)
            
        }, failure: { (error:NSError, data:Data?) in
            failure?(error)
        })
        
    }
    
}
