
import Foundation

public protocol Actionable: Serializable {
    
}

public extension Actionable {
    
    private var this:ActiveModel { return modelGetThis() }
    
    public func create(success:(()->Void)? = nil, failure:((NSError)->Void)? = nil) {
        Self.assertActivatedModel()
        
        success?()
        
        let url = Active.apiRootUrl + "/" + Self.modelApiPath() + Self.modelNamePlural()
        
        print(url)
        
    }
    
    public func save(success:(()->Void)? = nil, failure:((NSError)->Void)? = nil) {
        Self.assertActivatedModel()
        
        
    }
    
    public static func get(success:((Self, Self)->Void)? = nil, failure:((NSError)->Void)? = nil) {

    }
    
}
