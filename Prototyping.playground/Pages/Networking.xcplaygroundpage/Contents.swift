//: Networking
//: ==========

import UIKit
import XCPlayground

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true


//: Object Mapping

struct User: JSONDecodable {
    let id: Int
    let name: String
    let email: String?
    
    static func create(id: Int)(name: String)(email: String?) -> User {
        return User(id: id, name: name, email: email)
    }
    
    static func decode(json: JSON) -> User? {
        return _JSONParse(json) >>> { d in
            User.create
                <^> d <|  "id"
                <*> d <|  "name"
                <*> d <|* "email"
        }
    }
}


//: API Request

let request = NSURLRequest(URL: NSURL(string: "https://api.github.com/users/mkoehnke")!)
performRequest(request) { (result : Result<User>) in
    switch result {
    case let .Value(user): user.name
    case let .Error(error): error
    }
}


//: [Formatting](@next)
