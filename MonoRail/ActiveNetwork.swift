

import Foundation

class ActiveNetwork: Networking {

    class func call(_ verb:NetworkVerb, url urlstring:String, parameters:Dictionary<String, Any>? = nil, headers:Dictionary<String, Any>? = nil, success:@escaping (Dictionary<String, Any?>)->Void, failure:@escaping (NSError, Data?)->Void) {
        
        let params = parameters == nil ? [:] : parameters!
        let head = headers == nil ? [:] : headers!
        
        request(verb, url: urlstring, parameters: params, headers: head, success: { (data:Data, response:HTTPURLResponse) in
            
            do {
                guard let dictionary:Dictionary<String, Any?> = try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any?> else {
                    failure(NSError(domain: "An Error Occurred", code: 422, userInfo: nil), nil)
                    return
                }
                
                success(dictionary)
                
            } catch {
                failure(NSError(domain: "An Error Occurred", code: 422, userInfo: nil), nil)
            }
            
        }, failure: { (error:NSError, data:Data?) in
            failure(error, data)
        })
        
    }

}
