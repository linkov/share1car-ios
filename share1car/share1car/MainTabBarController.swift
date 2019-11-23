//
//  MainTabBarController.swift
//  share1car
//
//  Created by Alex Linkov on 11/1/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit


class MainTabBarController: UITabBarController {
    
    
    var firstTabBarItem: UITabBarItem?
    var secondTabBarItem: UITabBarItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        

        let firstVC = self.viewControllers![0] as UIViewController
        let secondVC = self.viewControllers![1]  as UIViewController
        let thirdVC = self.viewControllers![2]  as UIViewController
               
        let firstTab = UITabBarItem()
        firstTab.title = "Need a ride"
        firstTab.image = UIImage(named: "drop-off")
        
        firstVC.tabBarItem = firstTab
        
        firstTabBarItem = tabBarItem
        
        let secondTab = UITabBarItem()
        secondTab.title = "Have a car"
        secondTab.image = UIImage(named: "car")
        
        secondVC.tabBarItem = secondTab
        
        secondTabBarItem = secondVC.tabBarItem
        
         let thirdTab = UITabBarItem()
         thirdTab.title = "Settings"
         thirdTab.image = UIImage(named: "settings")
         
         thirdVC.tabBarItem = thirdTab

        self.tabBar.tintColor = UIColor.brandColor
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(onFeedbackScreenRequested(_:)), name: NotificationsManager.onFeedbackScreenRequestedNotification, object: nil)
        
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super .viewDidAppear(animated)
        NotificationsManager.shared.checkNotificationsStatus()
        
        
    }
    
    
    
    @objc func onFeedbackScreenRequested(_ notification:Notification) {
        
        let feedbackVC = storyboard!.instantiateViewController(withIdentifier: "FeedbackViewController") as! FeedbackViewController
        self.present(feedbackVC, animated: true, completion: nil)
    }
    


}
