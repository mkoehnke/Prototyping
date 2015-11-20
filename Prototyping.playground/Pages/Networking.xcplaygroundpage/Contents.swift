//: Networking
//: ==========

import UIKit
import XCPlayground

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true


//: Object Mapping

struct User: JSONDecodable {
    let id: Int
    let name: String?
    let email: String?
    
    static func create(id: Int)(name: String?)(email: String?) -> User {
        return User(id: id, name: name, email: email)
    }
    
    static func decode(json: JSON) -> User? {
        return _JSONParse(json) >>> { d in
            User.create
                <^> d <|  "id"
                <*> d <|* "name"
                <*> d <|* "email"
        }
    }
}

// TODO - Relationship Mapping

//: Network Request

let jsonRequest = NSURLRequest(URL: NSURL(string: "https://api.github.com/users/mkoehnke")!)
let jsonTask = performJSONRequest(jsonRequest) { (result : Result<User>) in
    switch result {
    case let .Value(user): user.name
    case let .Error(error): error
    }
}

//: Network Batch Request

public func performBatchRequest(requests: [NSURLRequest], callback: ([String : NSData]) -> ()) {
    let group = dispatch_group_create()
    var results = [String : NSData]()
    for request in requests {
        dispatch_group_enter(group)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, urlResponse, error in
            results[request.URL!.absoluteString] = data
            dispatch_group_leave(group)
        }
        task.resume()
    }
    dispatch_group_notify(group, dispatch_get_main_queue()) {
        callback(results)
    }
}

// TODO - Example

//: Image Request

let imageRequest = NSURLRequest(URL: NSURL(string: "https://avatars3.githubusercontent.com/u/583231?v=3&s=400")!)
let imageTask = performImageRequest(imageRequest) { (result : Result<UIImage>, request: NSURLRequest) in
    switch result {
    case let .Value(image): XCPlaygroundPage.currentPage.captureValue(image, withIdentifier: "image")
    case let .Error(error): error
    }
}

//: [Formatting](@next)
