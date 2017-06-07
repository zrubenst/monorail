
import UIKit

public class Persist {
    
    private init() {}
    private static var shared = Persist()
    
    internal var table:[String:[ActiveModel]] = [:]
    
    
    public class func register<T:ActiveModel>(_ register: T) {
        
        let identifier = register.modelGetInstanceID()
        
        if let instances:Array<ActiveModel> = shared.table[identifier] {
            
            for instance in instances {
                instance.sync(from: register)
            }
            
            shared.table[identifier]!.append(register)
            
            return
        }
        
        shared.table[identifier] = [register]
    }
    
    public class func push<T:ActiveModel>(synchronize newest:T) {
        let identifier = newest.modelGetInstanceID()
        
        if !isRegistered(register: newest) {
            register(newest)
        }
        
        if let instances:Array<ActiveModel> = shared.table[identifier] {
            
            for instance in instances {
                if instance != newest {
                    instance.sync(from: newest)
                }
            }
            
            return
        }
    }
    
    private class func isRegistered(register:ActiveModel) -> Bool {
        let identifier = register.modelGetInstanceID()
        
        if let instances:Array<ActiveModel> = shared.table[identifier] {
            for instance in instances {
                if instance == register {
                    return true
                }
            }
        }
        
        return false
    }
    
    class func remove(_ removal:ActiveModel) {
        let identifier = removal.modelGetInstanceID()
        
        if let instances:Array<ActiveModel> = shared.table[identifier] {
            for instance in instances {
                if instance == removal {
                    shared.table[identifier]?.remove(object: removal)
                }
            }
        }
        
    }
    
}





















//public class Persist {
//
//    private init() {}
//    private static var shared = Persist()
//    
//    internal var instances:[ActiveModel] = []
//    internal var observed:[ActiveModel] = []
//    
//    // Only validate when you know for certain that the model is the most up to date
//    // Example: directly after a network call
//    public class func validate<T: ActiveModel>(instance:T) -> T {
//        
//        let notificationName =  Notification.Name(instance.modelGetNotificationName())
//
//        for model in shared.instances {
//            if model.modelGetNotificationName() == instance.modelGetNotificationName() {
//                if !instance.modelPersisted { return instance }
//                
//                model.sync(from: instance)
//               
//                if !shared.observed.contains(instance) {
//                    shared.observed.append(instance)
//                    NotificationCenter.default.addObserver(instance, selector: #selector(ActiveModel.syncObserver(notification:)), name: notificationName, object: nil)
//                }
//                
//                NotificationCenter.default.post(name: notificationName, object: model)
//                
//                return model as! T
//            }
//        }
//        
//        NotificationCenter.default.addObserver(instance, selector: #selector(ActiveModel.syncObserver(notification:)), name: notificationName, object: nil)
//        
//        shared.observed.append(instance)
//        shared.instances.append(instance)
//        
//        return instance
//    }
//
//    
//    // Only sync when an oberserver is called on field change
//    public class func sync<T: ActiveModel>(instance:T, keyPath:String, newValue:Any?) {
//        for model in shared.instances {
//            if model.modelGetNotificationName() == instance.modelGetNotificationName() {
//                let modelT = model as! T
//                modelT.modelSetValue(newValue, forKey: keyPath)
//                
//                let notificationName =  Notification.Name(modelT.modelGetNotificationName())
//                NotificationCenter.default.post(name: notificationName, object: modelT)
//                
//                return
//            }
//        }
//    }
//    
//}
