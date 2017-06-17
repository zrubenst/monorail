//
//  Awakable.swift
//  MonoRail
//
//  Created by Zack Rubenstein on 6/7/17.
//  Copyright © 2017 ZRUBENST. All rights reserved.
//

import UIKit

internal protocol Awakable: class {
    static func awake()
}

class AwakableAid {
    
    static func trigger() {
        let typeCount = Int(objc_getClassList(nil, 0))
        let types = UnsafeMutablePointer<AnyClass?>.allocate(capacity: typeCount)
        let autoreleasingTypes = AutoreleasingUnsafeMutablePointer<AnyClass?>(types)
        objc_getClassList(autoreleasingTypes, Int32(typeCount))
        for index in 0 ..< typeCount { (types[index] as? Awakable.Type)?.awake() }
        types.deallocate(capacity: typeCount)
    }
    
}

extension UIApplication {
    
    private static let runOnce: Void = {
        MonoRail.Error.turnOnErrors()
        MonoRail.Registration.start()
        AwakableAid.trigger()
        MonoRail.Registration.end()
        MonoRail.Error.turnOffErrors()
    }()
    
    override open var next: UIResponder? {
        UIApplication.runOnce
        return super.next
    }
    
}
