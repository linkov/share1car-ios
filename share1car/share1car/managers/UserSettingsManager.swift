//
//  UserSettingsManager.swift
//  share1car
//
//  Created by Alex Linkov on 11/9/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit

class UserSettingsManager: NSObject {
    
    static let userSettingsMaximumPickUpDistance = "com.sdwr.share1car.usersettings.MaximumPickUpDistance"
    static let userSettingsMaximumDropOffDistance = "com.sdwr.share1car.usersettings.MaximumDropOffDistance"
    private static let userDefaults = UserDefaults.standard
    

    static let shared = UserSettingsManager()

     override init(){
        
        super.init()
        
    }
    
    func saveMaximumDropoffDistance(meters: Int){
        UserSettingsManager.userDefaults.set(meters,
                        forKey: UserSettingsManager.userSettingsMaximumDropOffDistance)
    }
    
    
    func getMaximumDropoffDistance() -> Int {
        let saved = UserSettingsManager.userDefaults.value(forKey: UserSettingsManager.userSettingsMaximumDropOffDistance) as? Int
        
        return (saved != nil) ? saved! : 600
    }
    
    
    
    func saveMaximumPickupDistance(meters: Int){
        UserSettingsManager.userDefaults.set(meters,
                        forKey: UserSettingsManager.userSettingsMaximumPickUpDistance)
    }
    
    
    func getMaximumPickupDistance() -> Int {
        
        let saved = UserSettingsManager.userDefaults.value(forKey: UserSettingsManager.userSettingsMaximumPickUpDistance) as? Int
        
        return (saved != nil) ? saved! : 600
    }
    
    
    static func clearUserData(){
        userDefaults.removeObject(forKey: UserSettingsManager.userSettingsMaximumPickUpDistance)
        userDefaults.removeObject(forKey: UserSettingsManager.userSettingsMaximumDropOffDistance)
    }
    
}
