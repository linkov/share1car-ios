//
//  FeedbackViewController.swift
//  share1car
//
//  Created by Alex Linkov on 11/12/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import Eureka
import JGProgressHUD

class FeedbackViewController: FormViewController {


     let hud = JGProgressHUD(style: .dark)
    
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        

        if (!AuthManager.shared.isLoggedIn()) {
            AuthManager.shared.presentAuthUIFrom(controller: self)
            return
        }
        
        
        initForm()
        
    }
    

    override func viewDidAppear(_ animated: Bool) {
        
        self.submitButton.layer.cornerRadius = 12
        self.dismissButton.layer.cornerRadius = 12
        
        self.view.bringSubviewToFront(self.submitButton)
        self.view.bringSubviewToFront(self.dismissButton)
        
        
    }
    
    
    
    
    func initForm() {
        
        
         form
           
            +++ Section("") {
                $0.tag = "clearsection"
                

            }
        
                +++ Section("") {
                    $0.tag = "section"
                    $0.header = HeaderFooterView<FeedbackHeaderView>(.nibFile(name: "FeedbackHeaderView", bundle: nil))
                    

                }
            
            
            <<< CustomRateRow() {
                $0.tag = "stars"
                $0.cell.backgroundColor = .clear
                $0.cell.height = { 69 }
                $0.cell.cosmosRating.rating = 3.0
                $0.cell.cosmosRating.settings.totalStars =  5
            }.onRowValidationChanged { cell, row in
                let rowIndex = row.indexPath!.row
                while row.section!.count > rowIndex + 1 && row.section?[rowIndex  + 1] is LabelRow {
                    row.section?.remove(at: rowIndex + 1)
                }
                if !row.isValid {
                    for (index, _) in row.validationErrors.map({ $0.msg }).enumerated() {
                        let labelRow = LabelRow() {
                            $0.title = "this field is required"
                            $0.cell.height = { 35 }
                        }
                        row.section?.insert(labelRow, at: row.indexPath!.row + index + 1)
                    }
                }
            }
                

                 <<< TextAreaRow(){ row in
                     row.textAreaHeight = TextAreaHeight.fixed(cellHeight: 90)
                     row.tag = "feedback"
                     row.placeholder = "Z. B. Was gefällt Dir? Was weniger? Wo gibt es Fehler? Welche Funktionalitäten wünscht Du dir in Zukunft?"
                 }


    }
    
    
    @IBAction func onSubmitTap(_ sender: Any) {
        
        
        let text: TextAreaRow? = form.rowBy(tag: "feedback")
        let stars: CustomRateRow? = form.rowBy(tag: "stars")
        
        let feedbackText =  text!.value ?? "No written feedback"


        
        DataManager.shared.sendFeedback(userID: AuthManager.shared.currentUserID()!, text: feedbackText, rating: stars!.value!) { (result, errorString) in
            
            if errorString != nil {
                Alerts.systemErrorAlert(error: errorString!, inController: self)
                
            }
            
            
            self.hud.indicatorView = JGProgressHUDSuccessIndicatorView()
            self.hud.textLabel.text = "Thank you!"
            self.hud.show(in: self.view)
            self.hud.dismiss(afterDelay: 1)
    
            self.dismiss(animated: true, completion: nil)
        }

        
    }
    
    
    @IBAction func onDismissTap(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    

}
