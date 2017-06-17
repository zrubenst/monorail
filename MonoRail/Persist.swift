
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
            for instance in instances {
                if instance == register { return }
            }
        }
        
        shared.table[identifier] = [register]
    }
    
    internal class func push<T:ActiveModel>(synchronize newest:T) {
        let identifier = newest.modelGetInstanceID()
        
        if !newest.isPersisted { return }
        
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
    
    internal class func destroy(_ removal:ActiveModel) {
        let identifier = removal.modelGetInstanceID()
        
        if let instances:Array<ActiveModel> = shared.table[identifier] {
            for instance in instances {
                instance.destroy()
            }
            shared.table.removeValue(forKey: identifier)
        }
    }
    
    
    ////////////////////
    // Instance scope helpers
    
    internal class func persistRelationships(from updated:ActiveModel) {
        
        let fields = updated.modelCustomFields()
        let table = tableByType()
        
        // loop through this models custom fields
        for custom in fields {
            
            let typeName = custom.model.className
            var inverse = custom.inverseOf
            
            // grab an array of all instances of the same type as the type this custom fields relates to
            guard let instances = table[typeName] else  { continue }
            if instances.first == nil { continue }
            let scheme = type(of: instances.first!).customScheme()
            
            // get the inverseOf this custom field if it isn't already defined
            if inverse == nil {
                if scheme[updated.className.snakeCased.lowercased() + "_id"] != nil {
                    inverse = updated.className.snakeCased.lowercased() + "_id"
                } else if scheme[updated.className.snakeCased.pluralize().lowercased()] != nil {
                    inverse = updated.className.snakeCased.pluralize().lowercased()
                } else {
                    continue // backout of this custom field if it cant be found (may not be backwards referenced, or there is an error)
                }
            }
            
            let currentValue:ActiveModel? = updated.modelGetValue(forKey: custom.field) as? ActiveModel
            
            // loop through all of the instances
            for instance in instances {
                if !instance.isPersisted { continue } // if instance is not persisted, ignore it
                
                // if the instance is referenced by this model, backwards reference the instance
                if let current:ActiveModel = currentValue {
                    if current.isReference(to: instance) {
                        instance.backwardsReference(field: inverse!, reference: updated)
                        continue
                    }
                }
                
                // grab the value for for the inverseOf field on the insatnce
                guard let related:ActiveModel = instance.modelGetValue(forKey: inverse!) as? ActiveModel else { continue }
                
                // if that field references this model...
                if related.isReference(to: updated) {
                    instance.dereference(field: inverse!, reference: updated) // dereference it
                }
            }
        }
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



