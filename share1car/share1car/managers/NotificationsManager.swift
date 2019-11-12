//
//  NotificationsManager.swift
//  share1car
//
//  Created by Alex Linkov on 11/10/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import FirebaseMessaging

class NotificationsManager: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {

    static let shared = NotificationsManager()

     override init(){
    }
    
    func isNotificationsEnabled() -> Bool {
        
     return  Messaging.messaging().fcmToken != nil
        
    }
    
    func registerForNotifications()  {
        
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self

          let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
          UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })

        UIApplication.shared.registerForRemoteNotifications()

    }
    
    //MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
    }
    
    
    //MARK: - MessagingDelegate
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        
    }
    
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
         print("Firebase registration token: \(fcmToken)")
        
        if  AuthManager.shared.currentUserID() == nil {
            return
        }
        
        DataManager.shared.setNotificationsToken(userID: AuthManager.shared.currentUserID()!, token: fcmToken)
        
    }
}
