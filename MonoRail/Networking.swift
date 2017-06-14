
import UIKit

public enum NetworkVerb: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    
    var method:String {
        return rawValue
    }
}

public protocol NetworkingDelegate {
    func updated(headers:Dictionary<String, Any>)
    func additionalHeaders() -> Dictionary<String, Any>
    func additionalParameters() -> Dictionary<String, Any>
}

struct NetworkResponse {
    let data:Data?
    let response:HTTPURLResponse?
    let error:NSError?
}

public class Networking: UIView {
    
    
    //////////////////////
    // Asynchronous
    
    class func request(_ verb:NetworkVerb, url urlstring:String, parameters:Dictionary<String, Any>, headers:Dictionary<String, Any>, success:@escaping (Data, HTTPURLResponse)->Void, failure:@escaping (NSError, Data?)->Void) {
        
        var urlstr = urlstring
        
        if verb == .get {
            urlstr += "?" + parameters.asRequestParameters
        }
        
        guard let url:URL = URL(string: urlstr) else {
            failure(NSError(domain: "An error occurred", code: 430, userInfo: nil), nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = verb.method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        if verb != .get {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            } catch {
                failure(NSError(domain: "An error occurred", code: 430, userInfo: nil), nil)
                return
            }
        }
        
        for (key, value) in headers {
            request.addValue(value as! String, forHTTPHeaderField: key)
        }
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        let task = session.dataTask(with: request, completionHandler: { data, aresponse, error in
            
            DispatchQueue.main.async{
                guard let response:HTTPURLResponse = aresponse as? HTTPURLResponse else {
                    failure(NSError(domain: "An error occurred", code: 430, userInfo: nil), data)
                    return
                }
                
                if error != nil {
                    failure(NSError(domain: error!.localizedDescription, code: response.statusCode, userInfo: nil), data)
                    return
                }
                
                if data == nil {
                    failure(NSError(domain: "An error occurred", code: response.statusCode, userInfo: nil), nil)
                    return
                }
                
                success(data!, response)
            }
        })
        
        task.resume()
    }
    
    
    //////////////////////
    // Synchronous
    
    class func request(_ verb:NetworkVerb, url urlstring:String, parameters:Dictionary<String, Any>, headers:Dictionary<String, Any>) -> NetworkResponse {
        
        var urlstr = urlstring
        
        if verb == .get {
            urlstr += "?" + parameters.asRequestParameters
        }
        
        guard let url:URL = URL(string: urlstr) else {
            return NetworkResponse(data: nil, response: nil, error: NSError(domain: "An error occurred", code: 430, userInfo: nil))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = verb.method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        if verb != .get {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            } catch {
                return NetworkResponse(data: nil, response: nil, error: NSError(domain: "An error occurred", code: 430, userInfo: nil))
            }
        }
        
        for (key, value) in headers {
            request.addValue(value as! String, forHTTPHeaderField: key)
        }
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        let semaphore = DispatchSemaphore(value: 0)
        var data: Data?
        var urlresponse: URLResponse?
        var error: Error?
        
        let task = session.dataTask(with: request, completionHandler: { somedata, aresponse, anerror in
            data = somedata
            urlresponse = aresponse
            error = anerror
            
            semaphore.signal()
        })
        task.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        guard let response:HTTPURLResponse = urlresponse as? HTTPURLResponse else {
            return NetworkResponse(data: data, response: nil, error: NSError(domain: "An error occurred", code: 430, userInfo: nil))
        }
        
        if error != nil {
            return NetworkResponse(data: data, response: nil, error: NSError(domain: error!.localizedDescription, code: response.statusCode, userInfo: nil))
        }
        
        if data == nil {
            return NetworkResponse(data: data, response: nil, error: NSError(domain: "An error occurred", code: response.statusCode, userInfo: nil))
        }
        
        return NetworkResponse(data: data, response: response, error: nil)
    }
    
}



//////////////////
// Networking Extensions

internal extension NSArray {
    
    func stringify() -> NSArray {
        return NSArray.stringify(array: self)
    }
    
    static func stringify(array:NSArray) -> NSArray {
        let strings:NSMutableArray = []
        for item in array {
            if item is NSArray {
                strings.add(NSArray.stringify(array: item as! NSArray))
            } else if item is NSDictionary {
                strings.add(NSDictionary.stringify(dictionary: item as! NSDictionary))
            } else {
                strings.add("\(item)")
            }
        }
        return strings
    }
    
}

internal extension NSDictionary {
    
    func stringify() -> NSDictionary {
        return NSDictionary.stringify(dictionary: self)
    }
    
    static func stringify(dictionary:NSDictionary) -> NSDictionary {
        let dict:NSMutableDictionary = [:]
        for (key, value) in dictionary {
            if value is NSArray {
                dict[key as! String] = NSArray.stringify(array: value as! NSArray)
            } else if value is NSDictionary {
                dict[key as! String] = NSDictionary.stringify(dictionary: value as! NSDictionary)
            } else {
                dict[key as! String] = "\(value)"
            }
        }
        return dict
    }

}

internal extension Dictionary {
    
    var asRequestParameters:String {
        
        let dict = NSDictionary(dictionary: self).stringify()
        
        let parameters = dict.map { (key, value) -> String in
            
            let aKey = (key as! String).stringForUrlEncoding()!
            
            if value is String {
                let aValue = (value as! String).stringForUrlEncoding()!
                return "\(aKey)=\(aValue)"
            } else if value is NSArray {
                
                var arrayParameters:[String] = []
                
                for item in (value as! NSArray) {
                    
                    guard let valueString:String = item as? String else {
                        assert(false, "Only Strings and literals are allowed this deep in request parameters")
                    }
                    
                    arrayParameters.append("\(aKey)[]=\(valueString.stringForUrlEncoding()!)")
                }
                
                return arrayParameters.joined(separator: "&")
                
            } else {
                assert(false, "Only Strings, literals and Arrays are allowed in request parameters")
            }
        }
        
        return parameters.joined(separator: "&")
    }

}

internal extension String {
    
    func stringForUrlEncoding() -> String? {
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        
        return self.addingPercentEncoding(withAllowedCharacters: allowed)
    }
    
}












