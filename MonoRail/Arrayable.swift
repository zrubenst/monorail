
import Foundation


public protocol Arrayable: Sequence, IteratorProtocol {
    
    associatedtype Model
    
    var _arrayCollection:NSArray { get set }
    var _arrayCurrent:Int { get set }
    
    init(models:Array<Model>, persisted:Bool)
    init(persistedArray:Bool)
    
    func ignore(_ m:Model)
}

public extension Arrayable {
    
    mutating public func next() -> Model? {
        if (_arrayCurrent < _arrayCollection.count) {
            _arrayCurrent += 1
            return _arrayCollection[_arrayCurrent-1] as? Model
        } else {
            _arrayCurrent = 0;
            return nil
        }
    }
    
    init(models:Array<Model>, persisted:Bool = true) {
        self.init(persistedArray: persisted)
        _arrayCollection = models as NSArray
    }
    
    subscript(index:Int) -> Model? {
        get {
            return _arrayCollection[index] as? Model
        }
    }
    
}
