
import Foundation


public protocol Arrayable: Sequence, IteratorProtocol {
    
    associatedtype Model
    
    var _arrayCollection:NSMutableArray { get set }
    var _arrayCurrent:Int { get set }
    
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
    
    subscript(index:Int) -> Model? {
        get {
            return _arrayCollection[index] as? Model
        }
    }
    
}
