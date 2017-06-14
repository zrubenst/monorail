

import Foundation

struct ActiveNetworkResponse {
    let data:Dictionary<String, Any?>?
    let error:NSError?
}

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
    
    class func call(_ verb:NetworkVerb, url urlstring:String, parameters:Dictionary<String, Any>? = nil, headers:Dictionary<String, Any>? = nil) -> ActiveNetworkResponse {
        
        let params = parameters == nil ? [:] : parameters!
        let head = headers == nil ? [:] : headers!
        
        let response = request(verb, url: urlstring, parameters: params, headers: head)
        
        if response.error != nil { return ActiveNetworkResponse(data: nil, error: response.error) }
        if response.data == nil { return ActiveNetworkResponse(data: nil, error: NSError(domain: "An Error Occurred", code: 422, userInfo: nil)) }
        
        do {
            guard let dictionary:Dictionary<String, Any?> = try JSONSerialization.jsonObject(with: response.data!, options: []) as? Dictionary<String, Any?> else {
                return ActiveNetworkResponse(data: nil, error: NSError(domain: "An Error Occurred", code: 422, userInfo: nil))
            }
            
            return ActiveNetworkResponse(data: dictionary, error: nil)
            
        } catch {
            return ActiveNetworkResponse(data: nil, error: NSError(domain: "An Error Occurred", code: 422, userInfo: nil))
        }
        
        
    }

}
