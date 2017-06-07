
import Foundation


/////////////////
// Field Types

internal var manyAssociationKey: UInt8 = 25

public extension Array {
    
    var modelsPersisted:Bool {
        get {
            guard let persisted = objc_getAssociatedObject(self, &manyAssociationKey) as? Bool else {
                return false
            }
            return persisted
        }
        set(newValue) {
            objc_setAssociatedObject(self, &manyAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
   
}

public typealias EnumType = String

public typealias Number = NSNumber
public typealias Boolean = NSNumber

public extension NSNumber {
    
    private static func get(_ num:Any) -> NSNumber {
        if num is Int {
            return NSNumber(value: num as! Int)
        } else if num is Double {
            return NSNumber(value: num as! Double)
        } else if num is Float {
            return NSNumber(value: num as! Float)
        } else if num is Bool {
            return NSNumber(value: num as! Bool)
        } else if num is CGFloat {
            return NSNumber(value: Float(num as! CGFloat))
        }
        assert(false, "Invalid number type for operation of Number")
    }
    
    internal class func sanitize(_ number: NSNumber) -> NSNumber {
        return number
    }
    
    internal static func sanitizeDouble(_ num:NSNumber) -> NSNumber {
        return NSNumber(value: num.doubleValue)
    }
    
    internal static func sanitizeInteger(_ num:NSNumber) -> NSNumber {
        return NSNumber(value: num.intValue)
    }
    

    // Operations
    
    public static func +(left:NSNumber, right: Any) -> NSNumber {
        return sanitize(NSNumber(value: left.doubleValue + get(num: right).doubleValue))
    }
    
    public static func -(left:NSNumber, right: Any) -> NSNumber {
        return sanitize(NSNumber(value: left.doubleValue - get(num: right).doubleValue))
    }
    
    public static func *(left:NSNumber, right: Any) -> NSNumber {
        return sanitize(NSNumber(value: left.doubleValue * get(num: right).doubleValue))
    }
    
    public static func /(left:NSNumber, right: Any) -> NSNumber {
        return sanitize(NSNumber(value: left.doubleValue / get(num: right).doubleValue))
    }
    
    public static func /(left:Any, right: NSNumber) -> NSNumber {
        return sanitize(NSNumber(value: right.doubleValue / get(num: left).doubleValue))
    }
    
    
    public static func +=(left:inout NSNumber, right: Any) {
        left = sanitize(NSNumber(value: left.doubleValue + get(num: right).doubleValue))
    }
    
    public static func -=(left:inout NSNumber, right: Any) {
        left = sanitize(NSNumber(value: left.doubleValue - get(num: right).doubleValue))
    }
    
    public static func *=(left:inout NSNumber, right: Any) {
        left = sanitize(NSNumber(value: left.doubleValue * get(num: right).doubleValue))
    }
    
    public static func /=(left:inout NSNumber, right: Any) {
        left = sanitize(NSNumber(value: left.doubleValue / get(num: right).doubleValue))
    }
    
    
}





