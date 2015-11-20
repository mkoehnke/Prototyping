//
// NetworkClient.swift
// Concepts inspired by https://robots.thoughtbot.com/efficient-json-in-swift-with-functional-concepts-and-generics
//

import UIKit
import Foundation

//========================================
// MARK: Response
//========================================

private struct Response {
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

private func resultFromOptional<A>(optional: A?, error: NSError!) -> Result<A> {
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

/// Takes the value of e.g. Result<Response> and passes it as parameter
/// to the right-hand side function of >>> (e.g. parseResponse)
public func >>><A, B>(a: Result<A>, f: A -> Result<B>) -> Result<B> {
    switch a {
    case let .Value(x):     return f(x)
    case let .Error(error): return .Error(error)
    }
}

/// If the value on the left-hand side of >>> is a non-optional,
/// it will be passed as parameter to the function on the right-
/// hand side
public func >>><A, B>(a: A?, f: A -> B?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .None
    }
}

/// If the value on the right-hand side of <^> is a non-optional,
/// it will be passed as parameter to the function on the left-
/// hand side
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
    let message = "Could not decode json object."
    return resultFromOptional(U.decode(json), error: NSError(domain: "de.mathiaskoehnke.prototyping", code: 2, userInfo: [NSLocalizedDescriptionKey : message]))
}

//========================================
// MARK: Perform JSON Requests
//========================================

public func performJSONRequest<A: JSONDecodable>(request: NSURLRequest, callback: (Result<A>) -> ()) -> NSURLSessionTask? {
    let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, urlResponse, error in
        callback(parseResult(data, urlResponse: urlResponse, error: error))
    }
    task.resume()
    return task
}

public func parseResult<A: JSONDecodable>(data: NSData!, urlResponse: NSURLResponse!, error: NSError!) -> Result<A> {
    let responseResult: Result<Response> = Result(error, Response(data: data, urlResponse: urlResponse))
    return responseResult >>> parseResponse >>> decodeJSON >>> decodeObject
}

private func parseResponse(response: Response) -> Result<NSData> {
    let successRange = 200..<300
    if !successRange.contains(response.statusCode) {
        let message = "Data could not be loaded."
        return .Error(NSError(domain: "de.mathiaskoehnke.prototyping", code: 1, userInfo: [NSLocalizedDescriptionKey : message]))
    }
    return Result(nil, response.data)
}

//========================================
// MARK: Perform Image Requests
//========================================

private let __imageCache = NSCache()
public func performImageRequest(request: NSURLRequest, callback: (Result<UIImage>, request: NSURLRequest) -> ()) -> NSURLSessionTask? {
    let cachedImage = fetchCachedImage(request)
    switch cachedImage {
    case .Value: callback(cachedImage, request: request)
    case .Error: return fetchRemoteImage(request, callback: callback)
    }
    return nil
}

private func fetchRemoteImage(request: NSURLRequest, callback: (Result<UIImage>, request: NSURLRequest) -> ()) -> NSURLSessionTask? {
    let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { (data, urlResponse, error) in
        let responseResult: Result<Response> = Result(error, Response(data: data!, urlResponse: urlResponse!))
        callback(responseResult >>> parseResponse >>> imageFromData(request), request: request)
    })
    task.resume()
    return task
}

private func fetchCachedImage(request: NSURLRequest) -> Result<UIImage> {
    var image : UIImage?
    if let data = __imageCache.objectForKey(request.URL!.absoluteString) as? NSPurgeableData where data.beginContentAccess() == true {
        image = UIImage(data: data)
        data.endContentAccess()
    }
    return resultFromOptional(image, error: NSError(domain: "<Your domain>", code: 1, userInfo: nil))
}

private func imageFromData(request: NSURLRequest)(data: NSData) -> Result<UIImage> {
    __imageCache.setObject(NSPurgeableData(data: data), forKey: request.URL!.absoluteString)
    return resultFromOptional(UIImage(data: data), error: NSError(domain: "<Your domain>", code: 1, userInfo: nil))
}

