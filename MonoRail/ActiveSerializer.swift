
import Foundation

public protocol ActiveSerializer {

    func serialize(data:[String:Any?]) -> ActiveModel
    
}

public protocol ActiveDeserializer {
    
    func deserialize(model:ActiveModel) -> [String:Any?]
    
}
