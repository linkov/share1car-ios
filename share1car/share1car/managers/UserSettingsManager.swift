//
//  UserSettingsManager.swift
//  share1car
//
//  Created by Alex Linkov on 11/9/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit

class UserSettingsManager: NSObject {
    
    static let userSettingsFCMToken = "com.sdwr.share1car.usersettings.FCMToken"
    static let userSettingsNotificationsAuthorized = "com.sdwr.share1car.usersettings.NotificationsAuthorized"
    
    static let userSettingsDriverDidSeeCarpoolOverlayOnboadrding = "com.sdwr.share1car.usersettings.DriverDidSeeCarpoolOverlayOnboadrding"
    static let userSettingsRiderDidSeeOverlayOnboadrding = "com.sdwr.share1car.usersettings.RiderDidSeeOverlayOnboadrding"
    static let userSettingsDriverDidSeeOverlayOnboadrding = "com.sdwr.share1car.usersettings.DriverDidSeeOverlayOnboadrding"
    static let userSettingsUserDidSeeTabBarOverlayOnboadrding = "com.sdwr.share1car.usersettings.UserDidSeeTabBarOverlayOnboadrding"
    
    static let userSettingsShouldSimulateMovement = "com.sdwr.share1car.usersettings.ShouldSimulateMovement"
    static let userSettingsImageURL = "com.sdwr.share1car.usersettings.ImageURL"
    
    static let userSettingsMaximumPickUpDistance = "com.sdwr.share1car.usersettings.MaximumPickUpDistance"
    static let userSettingsMaximumDropOffDistance = "com.sdwr.share1car.usersettings.MaximumDropOffDistance"
    private static let userDefaults = UserDefaults.standard
    

    static let shared = UserSettingsManager()

     override init(){
        
        super.init()
        
    }
    
    
    
    
    func getUserNotificationsAuthorizationEnabled() -> Bool {
        
      let saved = UserSettingsManager.userDefaults.value(forKey: UserSettingsManager.userSettingsNotificationsAuthorized) as? Bool
               
    return (saved != nil) ? saved! : false
    }
    
    
    func saveUserNotificationsAuthorizationEnabled(enabled: Bool) {
        
        UserSettingsManager.userDefaults.set(enabled,
                        forKey: UserSettingsManager.userSettingsNotificationsAuthorized)
    }
    
    
    func saveFCMToken(token: String) {
        
        UserSettingsManager.userDefaults.set(token,
                        forKey: UserSettingsManager.userSettingsFCMToken)
    }
    
    
    func getFCMToken() -> String? {
        let saved = UserSettingsManager.userDefaults.value(forKey: UserSettingsManager.userSettingsFCMToken) as? String
        
        return saved
    }

    
    func saveUserImageURL(imageURL: String) {
        
        UserSettingsManager.userDefaults.set(imageURL,
                        forKey: UserSettingsManager.userSettingsImageURL)
    }
    
    
    func getUserImageURL() -> String? {
        let saved = UserSettingsManager.userDefaults.value(forKey: UserSettingsManager.userSettingsImageURL) as? String
        
        return saved
    }
    
    
    
    func saveShouldSimulateMovement(shouldSimulate: Bool){
        UserSettingsManager.userDefaults.set(shouldSimulate,
                        forKey: UserSettingsManager.userSettingsShouldSimulateMovement)
    }
    
    
    func getShouldSimulateMovement() -> Bool {
        let saved = UserSettingsManager.userDefaults.value(forKey: UserSettingsManager.userSettingsShouldSimulateMovement) as? Bool
        
        return (saved != nil) ? saved! : false
    }
    
    
    
    func saveMaximumDropoffDistance(meters: Int){
        UserSettingsManager.userDefaults.set(meters,
                        forKey: UserSettingsManager.userSettingsMaximumDropOffDistance)
    }
    
    
    func getMaximumDropoffDistance() -> Int {
        let saved = UserSettingsManager.userDefaults.value(forKey: UserSettingsManager.userSettingsMaximumDropOffDistance) as? Int
        
        return (saved != nil) ? saved! : 1600
    }
    
    
    
    func saveMaximumPickupDistance(meters: Int){
        UserSettingsManager.userDefaults.set(meters,
                        forKey: UserSettingsManager.userSettingsMaximumPickUpDistance)
    }
    
    
    func getMaximumPickupDistance() -> Int {
        
        let saved = UserSettingsManager.userDefaults.value(forKey: UserSettingsManager.userSettingsMaximumPickUpDistance) as? Int
        
        return (saved != nil) ? saved! : 1600
    }
    
    
    static func clearUserData(){
        userDefaults.removeObject(forKey: AuthManager.userSessionKey)
        userDefaults.removeObject(forKey: UserSettingsManager.userSettingsFCMToken)
        userDefaults.removeObject(forKey: UserSettingsManager.userSettingsMaximumPickUpDistance)
        userDefaults.removeObject(forKey: UserSettingsManager.userSettingsMaximumDropOffDistance)
        userDefaults.removeObject(forKey: UserSettingsManager.userSettingsImageURL)
    }
    
}

//MARK: - Onboarding
extension UserSettingsManager {
    
    
    func saveDriverDidSeeCarpoolOverlayOnboadrding(didSee: Bool) {
        
        UserSettingsManager.userDefaults.set(didSee,
                        forKey: UserSettingsManager.userSettingsDriverDidSeeCarpoolOverlayOnboadrding)
    }
    
    
    func getDriverDidSeeCarpoolOverlayOnboadrding() -> Bool? {
        let saved = UserSettingsManager.userDefaults.value(forKey: UserSettingsManager.userSettingsDriverDidSeeCarpoolOverlayOnboadrding) as? Bool
        
        return (saved != nil) ? saved! : false
    }
    
    
    func saveDriverDidSeeOverlayOnboadrding(didSee: Bool){
           UserSettingsManager.userDefaults.set(didSee,
                           forKey: UserSettingsManager.userSettingsDriverDidSeeOverlayOnboadrding)
       }
       
       
       func getDriverDidSeeOverlayOnboadrding() -> Bool {
           let saved = UserSettingsManager.userDefaults.value(forKey: UserSettingsManager.userSettingsDriverDidSeeOverlayOnboadrding) as? Bool
           
           return (saved != nil) ? saved! : false
       }
       
       
       func saveRiderDidSeeOverlayOnboadrding(didSee: Bool){
           UserSettingsManager.userDefaults.set(didSee,
                           forKey: UserSettingsManager.userSettingsRiderDidSeeOverlayOnboadrding)
       }
       
       
       func getRiderDidSeeOverlayOnboadrding() -> Bool {
           let saved = UserSettingsManager.userDefaults.value(forKey: UserSettingsManager.userSettingsRiderDidSeeOverlayOnboadrding) as? Bool
           
           return (saved != nil) ? saved! : false
       }
    
    
    func saveUserDidSeeTabBarOverlayOnboadrding(didSee: Bool){
        UserSettingsManager.userDefaults.set(didSee,
                        forKey: UserSettingsManager.userSettingsUserDidSeeTabBarOverlayOnboadrding)
    }
    
    
    func getUserDidSeeTabBarOverlayOnboadrding() -> Bool {
        let saved = UserSettingsManager.userDefaults.value(forKey: UserSettingsManager.userSettingsUserDidSeeTabBarOverlayOnboadrding) as? Bool
        
        return (saved != nil) ? saved! : false
    }
       
       
    
}
