//
//  Alerts.swift
//  share1car
//
//  Created by Alex Linkov on 11/4/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import Foundation
import UIKit



class Alerts: NSObject {
    

    class func systemErrorAlert(error: String, inController: UIViewController) {
        
        DispatchQueue.main.async {
           
            
            let alertController = UIAlertController(
                title: "Error",
                message: error,
                preferredStyle: .alert
            )
            let cancel = UIAlertAction(title: "Close", style: .cancel, handler: { action in

                _ = inController.navigationController?.popViewController(animated: true)
            })

            alertController.addAction(cancel)
            inController.present(alertController, animated: true, completion: nil)
            
        }
        
        

    }

    
}
