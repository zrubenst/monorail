
import Foundation

public protocol Actionable: Serializable {
    
}

public extension Actionable {
    
    internal static var genericError:NSError { return NSError(domain: "An error occurred", code: 422, userInfo: nil) }
    
    public func save(success:(()->Void)? = nil, failure:((NSError)->Void)? = nil) {
        
//        let url = Active.apiRootUrl + "/" + Self.modelApiPath() + Self.modelNamePlural()
        
    }
    
    public static func get(id:String, success: @escaping (Self)->Void, failure:((NSError)->Void)? = nil) {
       
        let url = MonoRail.apiRootUrl + "/" + Self.modelApiPath() + Self.modelNamePlural() + "/" + id
        
        ActiveNetwork.call(.get, url: url, success: { (dict:Dictionary<String, Any?>) in
            
            guard let model = deserialzie(response: dict, action: .get) else {
                failure?(genericError)
                return
            }
            
            success(model)
            
        }, failure: { (error:NSError, data:Data?) in failure?(error) })
        
    }
    
}
