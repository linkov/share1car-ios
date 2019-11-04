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
    
    func fetchActiveRoutes() -> Void {
        
    }
    
    func updateUser(user: UserViewModel) -> Void {
        self.ref.child("users").child(user.UID!).setValue(["username": user.name]) { (error, ref) in
            
        }
    }
    
    
    
}
