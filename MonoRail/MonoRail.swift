//
//  MonoRail.swift
//  MonoRail
//
//  Created by Zack Rubenstein on 6/7/17.
//  Copyright © 2017 ZRUBENST. All rights reserved.
//

import UIKit

class MonoRail {

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

    
}
