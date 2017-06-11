
import UIKit

/////////////////
// Globals

var activeModelTypeAssociatedHandle: UInt8 = 21


/////////////////
// Extensions

internal extension NSObject {
    
    var className:String {
        return String(NSStringFromClass(type(of: self))).components(separatedBy: ".").last!
    }
    
    static var className:String {
        return String(NSStringFromClass(self.self)).components(separatedBy: ".").last!
    }
    
    var fullClassName:String {
        return String(NSStringFromClass(type(of: self)))
    }
    
    static var fullClassName:String {
        return String(NSStringFromClass(self.self))
    }
    
    var fieldNames:[String] {
        return Mirror(reflecting: self).children.flatMap { $0.label }
    }
    
    static var fieldNames:[String] {
        return Mirror(reflecting: self.init()).children.flatMap { $0.label }
    }
    
}

internal extension String {
    
    func capitalizingFirstLetter() -> String {
        let first = String(characters.prefix(1)).capitalized
        let other = String(characters.dropFirst())
        return first + other
    }
    
    var snakeCased:String {
        let pattern = "([a-z0-9])([A-Z])"
        
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: self.characters.count)
        return regex!.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2").lowercased()
    }
    
    var camelCased: String {
        let items = self.components(separatedBy: "_")
        var camelCase = ""
        items.enumerated().forEach {
            camelCase += 0 == $0 ? $1 : $1.capitalizingFirstLetter()
        }
        return camelCase
    }
}

extension Array where Element: Equatable {
    
    mutating func remove(object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}

