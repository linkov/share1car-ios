//
//  SettingsViewController.swift
//  share1car
//
//  Created by Alex Linkov on 11/10/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import Eureka

class SettingsViewController: FormViewController {
    
    @IBOutlet weak var saveButton: UIButton!
    var userID: String?
    var firstName: String = ""
    var phoneNumber: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.saveButton.layer.cornerRadius = 12
        
        self.userID = AuthManager.shared.currentUserID()!
       
        initForm()
        
        self.view.bringSubviewToFront(self.saveButton)
             
    }
    
    
    func initForm() {
        
        
         form

        
                +++ Section("User details") {
                    $0.tag = "section"
                    $0.header = HeaderFooterView<UserSettingsProfilePhotoHeaderView>(.nibFile(name: "UserSettingsProfilePhotoHeaderView", bundle: nil))

                }

                 <<< TextRow(){ row in
                     row.value = self.firstName
                     row.tag = "name"
                     row.title = "First & last name"
                     }.cellUpdate { cell, row in
                         row.value = self.firstName
                     }
            
                 <<< TextRow(){ row in
                     row.value = self.phoneNumber
                     row.tag = "phone"
                     row.title = "Phone number"
                     row.placeholder = "Phone number"
                 }.cellUpdate { cell, row in
                     row.value = self.phoneNumber
                 }
            
        +++ Section("Developer settings")
            <<< SwitchRow("simulateNavigation") {
                $0.tag = "shouldSimMovement"
                $0.title = "Simulate movement in turn by turn"
                $0.value = UserSettingsManager.shared.getShouldSimulateMovement()
            }
                
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        DataManager.shared.getUserDetails(userID: AuthManager.shared.currentUserID()!) { (details, error) in
                   if error != nil {
                       Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self)
                   }
                   
                   guard details != nil else {return}
                   
                   self.firstName = details!.name ?? ""
                   self.phoneNumber = details!.phone ?? ""
            self.tableView.reloadData()
                   
               }
    }
    
    
    @IBAction func didTapSave(_ sender: Any) {
        
        let phoneRow: TextRow? = form.rowBy(tag: "phone")
        let nameRow: TextRow? = form.rowBy(tag: "name")
        
        DataManager.shared.updateUser(userID: self.userID!, firstName: nameRow?.value ?? "", phone: phoneRow?.value ?? "")
        
        let shouldSimMovementRow: SwitchRow? = form.rowBy(tag: "shouldSimMovement")
        
        UserSettingsManager.shared.saveShouldSimulateMovement(shouldSimulate: (shouldSimMovementRow?.value!)!)
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
