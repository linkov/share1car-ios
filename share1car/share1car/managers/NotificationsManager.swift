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

    
    static let onKeyWindowDidBecomeAvailableNotification = Notification.Name("onKeyWindowDidBecomeAvailableNotification")
    static let onFeedbackScreenRequestedNotification = Notification.Name("onFeedbackScreenRequestedNotification")
    
    static let onCarpoolRequestNotificationReceivedNotification = Notification.Name("onCarpoolRequestNotificationReceivedNotification")
    static let onCarpoolAcceptNotificationReceivedNotification = Notification.Name("onCarpoolAcceptNotificationReceivedNotification")
  
    static let shared = NotificationsManager()

     override init(){

    }
    
    
    
    
    func checkNotificationsStatus() {
        
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
            let enabled = settings.authorizationStatus == .authorized
            UserSettingsManager.shared.saveUserNotificationsAuthorizationEnabled(enabled: enabled)
        })
        
        
    }

    
    func isNotificationsEnabled() -> Bool {
        
        
        let enabled = (Messaging.messaging().fcmToken != nil) && UserSettingsManager.shared.getUserNotificationsAuthorizationEnabled()
        return enabled
        
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
        
        
        UserSettingsManager.shared.saveFCMToken(token: fcmToken)
        
        if  AuthManager.shared.currentUserID() == nil {
            return
        }
        
        DataManager.shared.setNotificationsToken(userID: AuthManager.shared.currentUserID()!, token: fcmToken)
        
    }
}
