//
//  SettingsViewController.swift
//  share1car
//
//  Created by Alex Linkov on 11/10/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import Eureka

import JGProgressHUD

class SettingsViewController: FormViewController {
    
    @IBOutlet weak var saveButton: UIButton!
    var userID: String?
    var firstName: String = ""
    var email: String = ""
    var phoneNumber: String = ""
    
    let hud = JGProgressHUD(style: .dark)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.saveButton.layer.cornerRadius = 12
        
    
       
       
        
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
            
                <<< TextRow(){ row in
                    row.value = self.email
                    row.tag = "email"
                    row.title = "Email"
                    
                }.cellUpdate { cell, row in
                    row.value =  self.email
                }
            
        +++ Section("Developer settings")
            <<< SwitchRow("simulateNavigation") {
                $0.tag = "shouldSimMovement"
                $0.title = "Simulate turn by turn"
                $0.value = UserSettingsManager.shared.getShouldSimulateMovement()
            }.onChange({ (row) in
                
                UserSettingsManager.shared.saveShouldSimulateMovement(shouldSimulate: row.value!)
                self.hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                self.hud.textLabel.text = "Movement simulation is \( row.value == true ? "on" : "off" )"
                self.hud.show(in: self.view)
                self.hud.dismiss(afterDelay: 1)
            })
                
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        if (!AuthManager.shared.isLoggedIn()) {
            AuthManager.shared.presentAuthUIFrom(controller: self)
            return
        }
        
        self.form.removeAll()
        
        self.userID = AuthManager.shared.currentUserID()!
        
        DataManager.shared.getUserDetails(userID: AuthManager.shared.currentUserID()!) { (details, error) in
                   if error != nil {
                       Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self)
                   }
                   
                if details == nil {
                        
                }
                   
                   self.firstName = details!.name ?? ""
                   self.phoneNumber = details!.phone ?? ""
                    self.email = AuthManager.shared.authUI?.auth?.currentUser?.email ?? "no email"
                    self.initForm()
                   
               }
    }
    
    
    @IBAction func didTapSave(_ sender: Any) {
        
        let phoneRow: TextRow? = form.rowBy(tag: "phone")
        let nameRow: TextRow? = form.rowBy(tag: "name")
        
        DataManager.shared.updateUser(userID: self.userID!, firstName: nameRow?.value ?? "", phone: phoneRow?.value ?? "")
        
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
