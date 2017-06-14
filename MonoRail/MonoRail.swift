//
//  MonoRail.swift
//  MonoRail
//
//  Created by Zack Rubenstein on 6/7/17.
//  Copyright © 2017 ZRUBENST. All rights reserved.
//

import UIKit

public class MonoRail {

    private init() { }
    internal static var shared = MonoRail()
    internal var apiUrl:String = ""
    
    public class func register(apiRootUrl:String) {
        var apiRootUrl = apiRootUrl
        if apiRootUrl.hasSuffix("/") {
            apiRootUrl.remove(at: apiRootUrl.endIndex)
        }
        shared.apiUrl = apiRootUrl
    }
    
    public static var apiRootUrl:String {
        return shared.apiUrl
    }
    
    internal class Error {
        
        internal static var shared:Error = Error()
        private var _errors:Bool = true
        
        class func turnOffErrors() { shared._errors = false }
        class func turnOnErrors() { shared._errors = true }
        static var errorsOn:Bool { return shared._errors }
        
        class func warn(message:String, model:ActiveModel?=nil) {
            if !errorsOn { return }
            let name = model != nil ? model!.className + ":  " : ""
            print("\n<<<<<<<<<<<      MonoRail Warning      >>>>>>>>>>>")
            print(name + message)
            print("------------------------------------------------\n")
        }
        
        class func error(message:String, model:ActiveModel?=nil) {
            if !errorsOn { return }
            let name = model != nil ? model!.className + ":  " : ""
            print("\n<<<<<<<<<<<      MonoRail Error      >>>>>>>>>>>")
            print(name + message)
            print("------------------------------------------------\n")
            fatalError()
        }
        
        
        init() { }
        
    }
    
}
