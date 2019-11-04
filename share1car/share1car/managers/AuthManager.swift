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
    
    var currentUser: User?
    var isLoggedIn: Bool = false
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
    
    
    func loginWithEmailAndPassword(email: String, password: String) -> Void {
        
        
    }
    
    func presentAuthUIFrom(controller: UIViewController) {
        
        let authViewController = self.authUI!.authViewController()
        controller.present(authViewController, animated: true, completion: nil)
        
    }
    
    func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
        
        self.currentUser = Auth.auth().currentUser
        self.isLoggedIn = (Auth.auth().currentUser != nil)
    }
    
}
