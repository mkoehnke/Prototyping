//: Networking
//: ==========

import UIKit
import XCPlayground

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true


//: Object Mapping

struct User: JSONDecodable, CustomStringConvertible {
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
    
    var description: String {
        return name ?? ""
    }
}

// TODO - Relationship Mapping

//: Network Request
let jsonRequest1 = NSURLRequest(URL: NSURL(string: "https://api.github.com/users/mkoehnke")!)
let jsonRequest2 = NSURLRequest(URL: NSURL(string: "https://api.github.com/users/github")!)

func handleResult<A : JSONDecodable>(result: Result<A>) {
    switch result {
    case let .Value(value): print(value)
    case let .Error(error): print(error)
    }
}

let jsonTask = performJSONRequest(jsonRequest1) { (result : Result<User>) in
    handleResult(result)
}

//: Network Batch Request

performBatchRequest([jsonRequest1, jsonRequest2]) { results in
    let result1 : Result<User> = results[jsonRequest1]! >>> decodeJSON >>> decodeObject
    let result2 : Result<User> = results[jsonRequest2]! >>> decodeJSON >>> decodeObject
    handleResult(result1)
    handleResult(result2)
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
