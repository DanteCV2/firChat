//
//  User.swift
//  firApp
//
//  Created by Dante Cervantes Vega on 02/01/20.
//  Copyright © 2020 Dante Cervantes Vega. All rights reserved.
//

import UIKit

class User: NSObject {
    
    var id : String?
    var name : String?
    var email : String?
    var profileImageUrl : String?
    
    override init() {
        
    }
    
    init(dictionary: [String: Any]) {
        self.name = dictionary["name"] as? String
        self.email = dictionary["email"] as? String
        self.profileImageUrl = dictionary["profileImageUrl"] as? String
    }
}
