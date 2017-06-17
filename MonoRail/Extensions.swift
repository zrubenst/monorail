
import UIKit

/////////////////
// Globals

var activeModelTypeAssociatedHandle: UInt8 = 21
var activeModelImbedsAssociatedHandle: UInt8 = 22


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
    
    func lowercasingFirstLetter() -> String {
        let first = String(characters.prefix(1)).lowercased()
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
        return camelCase.lowercasingFirstLetter()
    }
    
    func index(of string: String, options: CompareOptions = .literal) -> Index? {
        return range(of: string, options: options)?.lowerBound
    }
    
    func endIndex(of string: String, options: CompareOptions = .literal) -> Index? {
        return range(of: string, options: options)?.upperBound
    }
    
    func indexes(of string: String, options: CompareOptions = .literal) -> [Index] {
        var result: [Index] = []
        var start = startIndex
        while let range = range(of: string, options: options, range: start..<endIndex) {
            result.append(range.lowerBound)
            start = range.upperBound
        }
        return result
    }
    
    func ranges(of string: String, options: CompareOptions = .literal) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var start = startIndex
        while let range = range(of: string, options: options, range: start..<endIndex) {
            result.append(range)
            start = range.upperBound
        }
        return result
    }
}

extension Array where Element: Equatable {
    
    mutating func remove(object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}

public extension Collection {
    
    func toJSON() -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted])
            guard let jsonString = String(data: jsonData, encoding: String.Encoding.utf8) else {
                return "{}"
            }
            return jsonString
        } catch {
            return "{}"
        }
    }
}

