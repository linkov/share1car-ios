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
    private static let userDefaults = UserDefaults.standard
    
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
        
        return getUserID() != nil
    }
    
    func currentUserID() -> String? {
        
         return getUserID()
    }
    
    
    func loginWithEmailAndPassword(email: String, password: String) -> Void {
        
        
    }
    
    func presentAuthUIFrom(controller: UIViewController) {
        
        
        self.authUI?.signIn(withProviderUI: FUIEmailAuth(), presenting: controller, defaultValue: nil)

        
//        let authViewController = self.authUI!.authViewController()
//        controller.present(authViewController, animated: true, completion: nil)
        
    }
    
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        
        let currentUser = Auth.auth().currentUser
        saveUserID(user: currentUser!.uid)
        
        let userID = authDataResult?.user.uid
        let name = authDataResult?.user.displayName
        if (name != nil) {
            DataManager.shared.updateUser(userID: userID!, firstName: name!, phone: "")
        }
    }
    
    
    
    // MARK: - Session
    
    func saveUserID(user: String){
        AuthManager.userDefaults.set(user,
                        forKey: AuthManager.userSessionKey)
    }
    
    
    func getUserID() -> String? {
        return AuthManager.userDefaults.value(forKey: AuthManager.userSessionKey) as? String
    }
    
    
    static func clearUserData(){
        userDefaults.removeObject(forKey: AuthManager.userSessionKey)
    }
    
}
