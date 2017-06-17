
import Foundation

internal extension ActiveModel {
    
    class Store {
        
        var modelActions:[ActiveModel.Action] = []
        var modelApiPath:String = ""
        var modelName:String = ""
        var modelNamePlural:String = ""
        var modelActivated:Bool = false
        
        var modelJsonRoot:String? = nil
        var modelSerializer:ActiveSerializer? = nil
        var modelDeserializer:ActiveDeserializer? = nil
        
        var modelFieldTypes:Dictionary<String, RawFieldType> = [:]
        var modelCustomFields:[ActiveModel.CustomField] = [] as! [ActiveModel.CustomField]
        var modelRegistrationFields:[String:ActiveModel.CustomField] = [:]
        
        class func from<T:ActiveModel>(_ classType:T.Type) -> ActiveModel.Store {
            let key = String(describing: classType.value(forKey: "self"))
            let store:ActiveModel.Store? = ActiveModel.StoreManager.shared.hash[key]
            
            if (store == nil) {
                ActiveModel.StoreManager.shared.register(class: classType)
                return from(classType)
            }
            
            return store!
        }
        
        var name:String
        
        init(name:String) {
            self.name = name
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
            hash[key] = ActiveModel.Store(name: key)
        }
        
    }
    
}





