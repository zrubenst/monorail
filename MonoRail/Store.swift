
import Foundation

internal extension ActiveModel {
    
    class Store {
        
        var modelActions:[ActiveModel.Action] = []
        var modelApiPath:String = ""
        var modelName:String = ""
        var modelNamePlural:String = ""
        var modelActivated:Bool = false
        
        class func from<T:ActiveModel>(_ classType:T.Type) -> ActiveModel.Store {
            let key = String(describing: classType.value(forKey: "self"))
            let store:ActiveModel.Store? = ActiveModel.StoreManager.shared.hash[key]
            
            if (store == nil) {
                ActiveModel.StoreManager.shared.register(class: classType)
                return from(classType)
            }
            
            return store!
        }
        
    }
    
    class StoreManager {
        
        private init() { }
        
        static var shared = ActiveModel.StoreManager()
        
        var hash:[String : ActiveModel.Store] = [:]
        
        func register<T:ActiveModel>(class classType:T.Type) {
            let key = String(describing: classType.value(forKey: "self"))
            if hash.keys.contains(key) {
                return
            }
            hash[key] = ActiveModel.Store()
        }
        
    }
    
}





