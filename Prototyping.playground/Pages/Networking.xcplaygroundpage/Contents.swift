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

let jsonRequest2 = NSURLRequest(URL: NSURL(string: "https://api.github.com/users/facebook")!)
performJSONRequests([jsonRequest, jsonRequest2]) { (results : [String : Result<User>]) in
    for result in results.values {
        switch result {
        case let .Value(user): user.name
        case let .Error(error): error
        }
    }
}

//: Image Request

let imageRequest = NSURLRequest(URL: NSURL(string: "https://avatars3.githubusercontent.com/u/583231?v=3&s=400")!)
let imageTask = performImageRequest(imageRequest) { (result : Result<UIImage>, request: NSURLRequest) in
    switch result {
    case let .Value(image): XCPlaygroundPage.currentPage.captureValue(image, withIdentifier: "image")
    case let .Error(error): error
    }
}

//: [Formatting](@next)
