//
//  AppDelegate.swift
//  share1car
//
//  Created by Alex Linkov on 11/1/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        return true
    }

    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        
         UserSettingsManager.shared.saveFCMToken(token: fcmToken)
        if AuthManager.shared.currentUserID() != nil {
              DataManager.shared.setNotificationsToken(userID: AuthManager.shared.currentUserID()!, token: fcmToken)
        }
      
    }
    
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print(remoteMessage)
    }

    // MARK: UISceneSession Lifecycle
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
    
    
    //MARK:- USER NOTIFICATION DELEGATE
    
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        
//        
//    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        
        
        
        
        print(notification.request.content.userInfo)

        if notification.request.identifier == "rig"{
            completionHandler( [.alert,.sound,.badge])
        }else{
            completionHandler([.alert, .badge, .sound])
        }

    }



    func userNotificationCenter(center: UNUserNotificationCenter, willPresentNotification notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        //Handle the notification
        completionHandler(
            [UNNotificationPresentationOptions.alert,
             UNNotificationPresentationOptions.sound,
             UNNotificationPresentationOptions.badge])
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        Messaging.messaging().apnsToken = deviceToken
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        print(deviceTokenString)
        NotificationsManager.shared.checkNotificationsStatus()

    }


    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print(#function)

    }



    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("i am not available in simulator \(error)")
    }


    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        


        let notificationType = Converters.notificationTypeFromNotificationUserInfo(userInfo: userInfo)
        
        if notificationType == "requested" || notificationType == "riderCancelled" {
            
            NotificationCenter.default.post(name: NotificationsManager.onCarpoolRequestNotificationReceivedNotification, object: nil, userInfo: userInfo)
            
        }
        
        if notificationType == "accepted" || notificationType == "rejected" || notificationType == "arrived"  {
            
            NotificationCenter.default.post(name: NotificationsManager.onCarpoolAcceptNotificationReceivedNotification, object: nil, userInfo: userInfo)
            
        }
        
        
        
        

        print(userInfo)

        switch application.applicationState {
        case .active:
            let content = UNMutableNotificationContent()
            if let title = userInfo["title"]
            {
                content.title = title as! String
            }
            if let title = userInfo["text"]
            {
                content.body = title as! String
            }
            content.userInfo = userInfo
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 0.5, repeats: false)
            let request = UNNotificationRequest(identifier:"rig", content: content, trigger: trigger)

            UNUserNotificationCenter.current().delegate = self
            UNUserNotificationCenter.current().add(request) { (error) in
                if let getError = error {
                    print(getError.localizedDescription)
                }
            }
        case .inactive:
             print("inactive")
            break
        case .background:
            print("background")
            break
        @unknown default:
            print("Unknown")
        }

    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {

        print(userInfo)

        switch application.applicationState {
        case .active:
            let content = UNMutableNotificationContent()
            if let title = userInfo["title"]
            {
                content.title = title as! String
            }
            if let title = userInfo["text"]
            {
                content.body = title as! String
            }
            content.userInfo = userInfo
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 0.5, repeats: false)
            let request = UNNotificationRequest(identifier:"rig", content: content, trigger: trigger)

            UNUserNotificationCenter.current().delegate = self
            UNUserNotificationCenter.current().add(request) { (error) in
                if let getError = error {
                    print(getError.localizedDescription)
                }
            }
        case .inactive:
             print("inactive")
            break
        case .background:
            print("background")
            break
        @unknown default:
            print("Unknown")
        }



    }


}

