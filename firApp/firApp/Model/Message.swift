//
//  Message.swift
//  firApp
//
//  Created by Dante Cervantes Vega on 02/01/20.
//  Copyright © 2020 Dante Cervantes Vega. All rights reserved.
//

import UIKit
import Firebase

class Message: NSObject {
    
    var fromId : String?
    var text : String?
    var timeStamp : NSNumber?
    var toId : String?
    
    func partenerId() -> String? {
        return fromId == Auth.auth().currentUser?.uid ? toId : fromId
    }
}
