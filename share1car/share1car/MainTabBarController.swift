//
//  MainTabBarController.swift
//  share1car
//
//  Created by Alex Linkov on 11/1/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let firstVC = self.viewControllers![0] as UIViewController
        let secondVC = self.viewControllers![1]  as UIViewController
               
        let firstTab = UITabBarItem()
        firstTab.title = "Need a ride"
        firstTab.image = UIImage(named: "walk")
        
        firstVC.tabBarItem = firstTab
        
        
        let secondTab = UITabBarItem()
        secondTab.title = "Have a car"
        secondTab.image = UIImage(named: "car")
        
        secondVC.tabBarItem = secondTab
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
