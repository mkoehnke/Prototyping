//
// NetworkClient.swift
// Concepts from https://robots.thoughtbot.com/efficient-json-in-swift-with-functional-concepts-and-generics
//

import Foundation

//========================================
// MARK: Perform Requests
//========================================

public func performRequest<A: JSONDecodable>(request: NSURLRequest, callback: (Result<A>) -> ()) {
    let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, urlResponse, error in
        callback(parseResult(data, urlResponse: urlResponse, error: error))
    }
    task.resume()
}

public func parseResult<A: JSONDecodable>(data: NSData!, urlResponse: NSURLResponse!, error: NSError!) -> Result<A> {
    let responseResult: Result<Response> = Result(error, Response(data: data, urlResponse: urlResponse))
    return responseResult >>> parseResponse
                          >>> decodeJSON
                          >>> decodeObject
}

func parseResponse(response: Response) -> Result<NSData> {
    let successRange = 200..<300
    if !successRange.contains(response.statusCode) {
        return .Error(NSError(domain: "<Your domain>", code: 1, userInfo: nil)) // customize the error message to your liking
    }
    return Result(nil, response.data)
}


//========================================
// MARK: JSON
//========================================

public typealias JSON = AnyObject
public typealias JSONObject = [String:AnyObject]
public typealias JSONArray = [AnyObject]

public protocol JSONDecodable {
    static func decode(json: JSON) -> Self?
}

public func _JSONParse<A>(object: JSON) -> A? {
    return object as? A
}

public func decodeJSON(data: NSData) -> Result<JSON> {
    let jsonOptional: JSON!
    var __error: NSError!
    
    do {
        jsonOptional = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0))
    } catch let caught as NSError {
        __error = caught
        jsonOptional = []
    }
    
    return resultFromOptional(jsonOptional, error: __error)
}

public func decodeObject<U: JSONDecodable>(json: JSON) -> Result<U> {
    return resultFromOptional(U.decode(json), error: NSError(domain: "<Your domain>", code: 1, userInfo: nil))
}

//========================================
// MARK: Response
//========================================

struct Response {
    let data: NSData
    var statusCode: Int = 500
    
    init(data: NSData, urlResponse: NSURLResponse) {
        self.data = data
        if let httpResponse = urlResponse as? NSHTTPURLResponse {
            self.statusCode = httpResponse.statusCode
        }
    }
}

public enum Result<A> {
    case Error(NSError)
    case Value(A)
    
    init(_ error: NSError?, _ value: A) {
        if let err = error {
            self = .Error(err)
        } else {
            self = .Value(value)
        }
    }
}

func resultFromOptional<A>(optional: A?, error: NSError!) -> Result<A> {
    if let a = optional {
        return .Value(a)
    } else {
        return .Error(error)
    }
}


//========================================
// MARK: Functional
//========================================

infix operator >>> { associativity left precedence 150 } // bind
infix operator <^> { associativity left } // Functor's fmap (usually <$>)
infix operator <*> { associativity left } // Applicative's apply

infix operator <|  { associativity left precedence 150 }
infix operator <|* { associativity left precedence 150 }

public func >>><A, B>(a: A?, f: A -> B?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}

public func >>><A, B>(a: Result<A>, f: A -> Result<B>) -> Result<B> {
    switch a {
    case let .Value(x):     return f(x)
    case let .Error(error): return .Error(error)
    }
}

public func <^><A, B>(f: A -> B, a: A?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}

public func <*><A, B>(f: (A -> B)?, a: A?) -> B? {
    if let x = a {
        if let fx = f {
            return fx(x)
        }
    }
    return .None
}

public func pure<A>(a: A) -> A? {
    return .Some(a)
}

public func <|<A>(object: JSONObject, key: String) -> A? {
    return object[key] >>> _JSONParse
}

public func <|*<A>(object: JSONObject, key: String) -> A?? {
    return pure(object[key] >>> _JSONParse)
}

