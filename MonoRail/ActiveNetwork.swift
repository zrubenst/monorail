

import Foundation

public protocol ActiveNetworkDelegate {
    
}

public struct ActiveNetworkResponse {
    let data:Dictionary<String, Any?>?
    let error:ActiveNetworkError?
}

public class ActiveNetworkError {
    
    public var data:NSDictionary?
    public var domain:String
    public var code:Int
    
    public init(error:NSError, dict:NSDictionary?) {
        data = dict
        domain = error.domain
        code = error.code
    }
    
    public var description:String {
        var d = "\(code): \(domain)"
        if data != nil {
            d += "\n\((data as! Dictionary<String, Any?>).toJSON())"
        }
        return d
    }
    
}

public class ActiveNetwork: Networking {

    public class func call(_ verb:NetworkVerb, url urlstring:String, parameters:Dictionary<String, Any?>? = nil, headers:Dictionary<String, Any?>? = nil, success:((Dictionary<String, Any?>)->Void)? = nil, failure:((ActiveNetworkError)->Void)? = nil) {
        
        let params = parameters == nil ? [:] : parameters!
        let head = headers == nil ? [:] : headers!
        
        request(verb, url: urlstring, parameters: params, headers: head, success: { (data:Data, response:HTTPURLResponse) in
            
            if verb == .delete && response.statusCode >= 200 && response.statusCode <= 299 {
                success?(Dictionary<String, Any?>())
                return
            }
            
            do {
                guard let dictionary:Dictionary<String, Any?> = try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, Any?> else {
                    failure?(ActiveNetworkError(error: NSError(domain: "An Error Occurred", code: 422, userInfo: nil), dict: nil))
                    return
                }
                
                if response.statusCode < 200 || response.statusCode > 299 {
                    failure?(ActiveNetworkError(error: NSError(domain: "An Error Occurred", code: response.statusCode, userInfo: nil), dict: dictionary as NSDictionary))
                    return
                }
                
                success?(dictionary)
                
            } catch {
                failure?(ActiveNetworkError(error: NSError(domain: "An Error Occurred", code: 422, userInfo: nil), dict: nil))
            }
            
        }, failure: { (error:NSError, data:Data?) in
            failure?(ActiveNetworkError(error: error, dict: nil))
        })
        
    }
    
    public class func call(_ verb:NetworkVerb, url urlstring:String, parameters:Dictionary<String, Any?>? = nil, headers:Dictionary<String, Any?>? = nil) -> ActiveNetworkResponse {
        
        let params = parameters == nil ? [:] : parameters!
        let head = headers == nil ? [:] : headers!
        
        let response = request(verb, url: urlstring, parameters: params, headers: head)
        
        if response.error != nil { return ActiveNetworkResponse(data: nil, error: ActiveNetworkError(error: response.error!, dict: nil)) }
        if response.data == nil { return ActiveNetworkResponse(data: nil, error: ActiveNetworkError(error: NSError(domain: "An Error Occurred", code: 422, userInfo: nil), dict: nil)) }
        
        do {
            guard let dictionary:Dictionary<String, Any?> = try JSONSerialization.jsonObject(with: response.data!, options: []) as? Dictionary<String, Any?> else {
                return ActiveNetworkResponse(data: nil, error: ActiveNetworkError(error: NSError(domain: "An Error Occurred", code: 422, userInfo: nil), dict: nil))
            }
            
            if response.response != nil && response.response!.statusCode < 200 || response.response!.statusCode > 299 {
                return ActiveNetworkResponse(data: nil, error: ActiveNetworkError(error: NSError(domain: "An Error Occurred", code: response.response!.statusCode, userInfo: nil), dict: dictionary as NSDictionary))
            }
            
            return ActiveNetworkResponse(data: dictionary, error: nil)
            
        } catch {
            return ActiveNetworkResponse(data: nil, error: ActiveNetworkError(error: NSError(domain: "An Error Occurred", code: 422, userInfo: nil), dict: nil))
        }
        
        
    }

}
