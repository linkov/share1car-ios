//
//  DataManager.swift
//  share1car
//
//  Created by Alex Linkov on 11/1/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import Foundation
import Firebase

class DataManager: NSObject {
    
    static let shared = DataManager()
    var ref: DatabaseReference!

     override init(){
        ref = Database.database().reference()
    }
    
    
    
    func updateUser(user: UserViewModel) -> void {
        
    }
    
    
    
}
