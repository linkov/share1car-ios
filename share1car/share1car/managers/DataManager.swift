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
    
    func userProfilePicFirebaseReference(userID: String) -> StorageReference? {
        return storageRef.child(userID)
    }
    
    
    func getUserPhotoURL(userID: String, completion: @escaping imageurl_error_block) {
        let userImageRef = storageRef.child(userID)
        
        userImageRef.downloadURL { (url, error) in
            if error != nil {
                 completion(nil, error)
                 return
             }
            completion(url?.absoluteString, nil)
        }
        
    }
    
    
    func getTotalUserCount(completion: @escaping result_errordescription_block) {
        
        self.ref.child("user_data").observeSingleEvent(of: .value, with: { (snapshot) in
            
            let array = snapshot.value as! [String:Any]
            
            completion(array.count,nil)
            
        }) { (error) in
            
            completion(nil, error.localizedDescription)
        }
    }
    
    
    func getUserPhoto(userID: String, completion: @escaping imagedata_error_block) {
        let userImageRef = storageRef.child(userID)
        
        userImageRef.getData(maxSize: 1902077) { (data, error) in
            if error != nil {
                completion(nil, error)
                return
            }
            
            completion(data!, nil)
            
        }
        
    }
    
    func setNotificationsToken(userID: String, token: String) {
        self.ref.child("user_data").child(userID).child("token").setValue(token)
    }
    
    func sendFeedback(userID: String?, text: String, rating: Int, completion: @escaping result_errordescription_block) {
        
        let user = userID ?? "_anonymous"
        self.ref.child("Feedbacks").child(user).setValue(
            ["message": text,
             "rating": rating,
             "uid": user
        ]) { (error, ref) in
         
            if error != nil {
                completion(nil, error!.localizedDescription)
                return
            }
            completion(ref, nil)
        }
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
    
    func getUserDetails(userID: String, userDetailscompletion: @escaping userdetails_error_block) {
        
        let photoURL = UserSettingsManager.shared.getUserImageURL()
        self.ref.child("user_data").child(userID).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let result = snapshot.value {
                
                
                
                let res = result as? [String:Any]
                print(res)
                if res == nil {
                    userDetailscompletion(nil, nil)
                    return
                }
                var details = S1CUserDetails()
                details.UID = userID
                details.name = res!["firstName"] as? String
                details.phone = res!["phone"] as? String
                details.photoURL = photoURL
                userDetailscompletion(details, nil)
            }
                        
          }) { (error) in
            userDetailscompletion(nil, error)
        }
        

    }
    
    func updateUserPhone(userID: String, phoneNumber: String) {
        
        self.ref.child("user_data").child(userID).child("phone").setValue(phoneNumber) { (error, ref) in
            
        }
    }
    
    func updateUser(userID: String, firstName: String, phone: String) -> Void {
        self.ref.child("user_data").child(userID).setValue(["platform":"iOS", "firstName": firstName, "phone": phone]) { (error, ref) in
            
        }
    }
    
    
    
}
