
import Foundation



public class Active: NSObject {
    
    internal static var apiRootUrl:String {
        return MonoRail.apiRootUrl
    }
    
    internal class Error {
        
        class func warn(message:String, model:ActiveModel?=nil) {
            let name = model != nil ? model!.className + ":  " : ""
            print("\n<<<<<<<<<<<      Active Warning      >>>>>>>>>>>")
            print(name + message)
            print("------------------------------------------------\n")
        }
        
        init() { }
        
    }
    
}
