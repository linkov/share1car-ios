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
    var storageRef: StorageReference!

     override init(){
        storageRef = Storage.storage().reference()
        ref = Database.database().reference()
    }
    
    func fetchActiveRoutes() -> Void {
        
    }
    
    func profilePicFirebaseReference() -> StorageReference? {
        return storageRef.child(AuthManager.shared.currentUserID()!)
    }
    
    func updateUserPhoto(imageData: Data, completion: @escaping imageurl_error_block) {
        let userImageRef = storageRef.child(AuthManager.shared.currentUserID()!)
        
        _ = userImageRef.putData(imageData, metadata: nil) { (metadata, error) in
            
            if error != nil {
                print(error?.localizedDescription as Any)
                completion(nil, error!)
                return
            }
          
          userImageRef.downloadURL { (url, error) in
            guard url != nil else {
                print(error?.localizedDescription as Any)
                completion(nil, error!)
              return
            }
            
            
            
            UserSettingsManager.shared.saveUserImageURL(imageURL: url!.absoluteString)
            completion(url!.absoluteString, nil)
            
            
          }
        }
        
    }
    
    func getUserDetails(userID: String, completion: @escaping userdetails_error_block) {
        
        self.ref.child("user_data").child(userID).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let result = snapshot.value {
                
                
                
                let res = result as? [String:Any]
                
                if res == nil {
                    completion(nil, nil)
                    return
                }
                let details = S1CUserDetails()
                details.name = res!["firstName"] as? String
                details.phone = res!["phone"] as? String
                completion(details, nil)
            }
                        
          }) { (error) in
            completion(nil, error)
        }
    }
    
    
    func updateUser(userID: String, firstName: String, phone: String) -> Void {
        self.ref.child("user_data").child(userID).setValue(["firstName": firstName, "phone": phone]) { (error, ref) in
            
        }
    }
    
    
    
}
