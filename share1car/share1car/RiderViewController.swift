//
//  RiderViewController.swift
//  share1car
//
//  Created by Alex Linkov on 11/1/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit


class RiderViewController: UIViewController {

    
    override func viewDidAppear(_ animated: Bool) {
    
        
        if (!AuthManager.shared.isLoggedIn) {
            AuthManager.shared.presentAuthUIFrom(controller: self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
