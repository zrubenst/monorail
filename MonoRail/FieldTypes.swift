
import Foundation


/////////////////
// Field Types

public typealias Enumeration = String
public typealias Number = NSNumber
public typealias Boolean = NSNumber
public typealias Hash = NSDictionary
public typealias List = NSArray

public extension String { static var Field:Optional<String> { return Optional.some(String()) } }
public extension NSDictionary { static var Field:Optional<NSDictionary> { return Optional.some(NSDictionary()) } }
public extension NSArray { static var Field:Optional<NSArray> { return Optional.some(NSArray()) } }
public extension Date { static var Field:Optional<Date> { return Optional.some(Date()) } }
public extension Number { static var Field:Optional<Number> { return Optional.some(Number(value: 1)) } }
public struct Enum { public static var Field:Optional<String> { return Optional.some(Enumeration()) } }

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
        return NSNumber(value: 0)
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
