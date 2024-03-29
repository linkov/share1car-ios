//
//  AuthManager.swift
//  share1car
//
//  Created by Alex Linkov on 11/1/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import Foundation
import FirebaseUI
import Firebase


class AuthManager: NSObject, FUIAuthDelegate {
    
    static let userSessionKey = "com.sdwr.share1car.usersession"
    
    var presentingVC: UIViewController?
    var authUI: FUIAuth?
    
    static let shared = AuthManager()

     override init(){
        
        super.init()
        self.authUI = FUIAuth.defaultAuthUI()
        self.authUI!.delegate = self
        let providers: [FUIAuthProvider] = [
            FUIEmailAuth()
        ]
        self.authUI!.providers = providers
        
    }

    
    func isLoggedIn() -> Bool {
        let useIDExists = (getUserID() != nil)
        return useIDExists
    }
    
    func currentUserID() -> String? {
        
         return getUserID()
    }
    
    
    func logout(completion: @escaping didfinish_block) {
        UserSettingsManager.shared.clearUserDefaultsOnFirstLaunch()
        clearUserData()
        completion(true)
        
    }
    
    func presentAuthUIFrom(controller: UIViewController) {
        
        
        self.authUI?.signIn(withProviderUI: FUIEmailAuth(), presenting: controller, defaultValue: nil)

        
    }
    
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        
        if error != nil {
            Alerts.systemErrorAlert(error: error!.localizedDescription, inController: presentingVC!)
            return
        }
        
        
        
        let currentUser = Auth.auth().currentUser
        if currentUser == nil {
            return
        }
        saveUserID(user: currentUser!.uid)
        
        let userID = authDataResult?.user.uid
        let name = authDataResult?.user.displayName
        if (name != nil && userID != nil) {
            DataManager.shared.updateUser(userID: userID!, firstName: name!, phone: "")
            DataManager.shared.getUserPhotoURL(userID: userID!) { (url, error) in
                if error != nil {
                    print(error?.localizedDescription as Any)
                    return
                }
                
                UserSettingsManager.shared.saveUserImageURL(imageURL: url)
            }
        }
        
        let currentToken = UserSettingsManager.shared.getFCMToken()
        if currentToken != nil {
             DataManager.shared.setNotificationsToken(userID: AuthManager.shared.currentUserID()!, token: currentToken!)
        } else {
            InstanceID.instanceID().instanceID { (result, error) in
              if let error = error {
                print("Error fetching remote instance ID: \(error)")
              } else if let result = result {
                print("Remote instance ID token: \(result.token)")
                UserSettingsManager.shared.saveFCMToken(token: result.token)
                 DataManager.shared.setNotificationsToken(userID: AuthManager.shared.currentUserID()!, token: result.token)
              }
            }
        }
        
        if (authDataResult?.additionalUserInfo?.isNewUser)! {
            OnboardingManager.shared.showPhoneNumberOnboarding()
        }
        
       
    }
    
    
    
    // MARK: - Session
    
    func saveUserID(user: String){
        UserDefaults.standard.set(user,
                        forKey: AuthManager.userSessionKey)
    }
    
    
    func getUserID() -> String? {
        return UserDefaults.standard.value(forKey: AuthManager.userSessionKey) as? String
    }
    
    
    func clearUserData(){
        try!  Auth.auth().signOut()
        UserDefaults.standard.removeObject(forKey: AuthManager.userSessionKey)
        UserSettingsManager.clearUserData()
        UserDefaults.standard.synchronize()
    }
    
}
