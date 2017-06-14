
import UIKit

public class Persist {
    
    private init() {}
    internal static var shared = Persist()
    
    internal var table:[String:[ActiveModel]] = [:]
    internal var models:[ActiveModel.Type] = []
    
    
    ////////////////////
    // Instance scope
    
    internal class func register<T:ActiveModel>(_ register: T) {
        
        let identifier = register.modelGetInstanceID()
        
        if let instances:Array<ActiveModel> = shared.table[identifier] {
            
            var shouldAppend = true
            
            for instance in instances {
                instance.sync(from: register)
                if instance == register { shouldAppend = false }
            }
            
            if shouldAppend { shared.table[identifier]!.append(register) }
            
            return
        }
        
        shared.table[identifier] = [register]
    }
    
    internal class func push<T:ActiveModel>(synchronize newest:T) {
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
        }
        
        persistRelationships(from: newest)
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
    
    internal class func persisted(like:ActiveModel) -> ActiveModel? {
        let identifier = like.modelGetInstanceID()
        
        if let array:[ActiveModel] = shared.table[identifier] {
            return array.last
        }
        
        return nil
    }
    
    internal class func persisted(className:String, id:String) -> ActiveModel? {
        let identifier = className + "_" + id
        
        if let array:[ActiveModel] = shared.table[identifier] {
            return array.last
        }
        
        return nil
    }
    
    internal class func remove(_ removal:ActiveModel) {
        let identifier = removal.modelGetInstanceID()
        
        if let instances:Array<ActiveModel> = shared.table[identifier] {
            for instance in instances {
                if instance == removal {
                    shared.table[identifier]?.remove(object: removal)
                }
            }
        }
        
    }
    
    
    ////////////////////
    // Instance scope helpers
    
    internal class func persistRelationships(from updated:ActiveModel) {
    
        
        
    }
    
    internal class func tableByType() -> [String:[ActiveModel]] {
        
        var table = [String:[ActiveModel]]()
        
        for (_, models) in shared.table {
            guard let instance = models.first else { continue }
            if table[instance.className] == nil { table[instance.className] = [] }
            table[instance.className]?.append(contentsOf: models)
        }
        
        return table
    }
    
    struct Affected {
        let field:String
        let custom:ActiveModel.CustomField
        let model:ActiveModel
    }
    
    
    ////////////////////
    // Model scope
    
    internal class func register(model:ActiveModel.Type) {
        shared.models.append(model)
    }
    
    
    
    
    ////////////////////
    // Printing
    
    public class func printOut() {
        
        for (model, instances) in shared.table {
            
            print(model)
            print("---------------------")
            
            for instance in instances {
                print(Unmanaged.passUnretained(instance).toOpaque())
            }
            
            print("\n\n")
            
        }
        
    }
    
}



