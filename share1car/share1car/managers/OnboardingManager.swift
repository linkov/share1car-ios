//
//  OnboardingManager.swift
//  share1car
//
//  Created by Alex Linkov on 11/12/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import BLTNBoard
import MapboxNavigation
import MaterialShowcase

import JGProgressHUD

class OnboardingManager: NSObject, ImagePickerDelegate, MaterialShowcaseDelegate {
    
    var mapView: NavigationMapView?
    var imagepicker: ImagePicker?
    
    let sequence = MaterialShowcaseSequence()

    
    let hud = JGProgressHUD(style: .light)
    
    var bulletinManager: BLTNItemManager?
    var presentingViewController: UIViewController?
    static let shared = OnboardingManager()
    
    override init(){
        
    }
    
    
    func changePresentingViewController(viewController: UIViewController) {
        imagepicker = ImagePicker(presentationController: viewController, delegate: self)
        self.presentingViewController = viewController
    }
    
    
    
    func showOnAppOpenOnboardingReturning(mapView: NavigationMapView) -> Bool {
        self.mapView = mapView
        
        if (UserSettingsManager.shared.getUserDidSeeTabBarOverlayOnboadrding() == false) {

            let tabBarVC = self.presentingViewController!.parent as! UITabBarController
            showTabBarOverlayOnboarding(tabBar: tabBarVC.tabBar)
            return true

        }

        if (!LocationManager.shared.locationEnabled()) {
            
            showLocationOnboarding()
            
        }
        
        return false
                     
    }
    
    func showOnMapTapOnboardingReturning(mapView: NavigationMapView) -> Bool {
        
        self.mapView = mapView
        
        if (!AuthManager.shared.isLoggedIn()) {
              AuthManager.shared.presentAuthUIFrom(controller: presentingViewController!)
              return true
          }
          
        if (!NotificationsManager.shared.isNotificationsEnabled()) {
            showNotificationsOnboarding()
            return true
        }
          
          
          if (UserSettingsManager.shared.getUserImageURL() == nil) {
              showProfilePicOnboarding()
              return true
          }
          
          
          

        
        return false
    }
    
    func showCarpoolOverlayOnboardingReturning(carpoolButton: UIButton) -> Bool {
        
        if (UserSettingsManager.shared.getDriverDidSeeCarpoolOverlayOnboadrding() == false) {
            UserSettingsManager.shared.saveDriverDidSeeCarpoolOverlayOnboadrding(didSee: true)
            
//            let showcase = MaterialShowcase()
//            showcase.delegate = self
//            showcase.backgroundPromptColor = .brandColor
//            showcase.setTargetView(button: carpoolButton)
//            showcase.primaryText = "Carpool spontan anbieten"
//            showcase.secondaryText = "Um einen Carpool (Mitfahrt) spontan anzubieten, wähle auf der Karte dein Ziel aus, setz Dich ins Auto und starte hier die Navigation. Du kannst Mitfahranfragen während der Fahrt akzeptieren oder ablehnen."
//            showcase.show(completion: nil)
//            return true
//        } else {
//            return false
//        }
        
            return true
        
        } else {
            return false
        }
    }
    
    func showTabBarOverlayOnboarding(tabBar: UITabBar) {
        
        if (UserSettingsManager.shared.getUserDidSeeTabBarOverlayOnboadrding() == true) {
            return
        }
        
        let showcase = MaterialShowcase()
        showcase.delegate = self
        showcase.setTargetView(tabBar: tabBar, itemIndex: 0)
        showcase.primaryText = "Als Mitfahrer"
        showcase.secondaryText = "Wenn eine Fahrt angeboten wird (rote Route auf der Karte), kannst Du als Mitfahrer durch einen kurzen Klick auf die Route dein Ziel auswählen."
        
        let showcase1 = MaterialShowcase()
        showcase1.delegate = self
        showcase1.setTargetView(tabBar: tabBar, itemIndex: 1)
        showcase1.primaryText = "Als Fahrer"
        showcase1.secondaryText = "Als Fahrer kannst Du durch einen kurzen Klick auf die Karte oder über die Suchleiste Dein Fahrtziel auswählen."
        
        sequence.temp(showcase).temp(showcase1).start()
                
        UserSettingsManager.shared.saveUserDidSeeTabBarOverlayOnboadrding(didSee: true)
    }


    
    
    func showLocationOnboarding() {
        
        let locationPermissions = BulletinDataSource.makeLocationPage()
        locationPermissions.actionHandler = { (item: BLTNActionItem) in
            
            LocationManager.shared.requestLocationPermissions { (didGetPermission) in
                locationPermissions.manager?.dismissBulletin()
                self.mapView!.showsUserLocation = true
                LocationManager.shared.findUserLocation { (coord) in
                        
                    self.mapView!.setCenter(coord, zoomLevel: 12, animated: false)
                }
                
                
            }

        }
        bulletinManager = BLTNItemManager(rootItem: locationPermissions)
        bulletinManager!.backgroundViewStyle = .dimmed
        bulletinManager!.statusBarAppearance = .hidden
        bulletinManager!.showBulletin(above: presentingViewController!)
    }
    
    func showProfilePicOnboarding() {
        
        let profilePic = BulletinDataSource.makeProfilePicRequestPage()
        profilePic.actionHandler = { (item: BLTNActionItem) in

            profilePic.manager?.dismissBulletin()
            self.imagepicker?.present(from: self.presentingViewController!.view)
        }
        bulletinManager = BLTNItemManager(rootItem: profilePic)
        bulletinManager!.backgroundViewStyle = .dimmed
        bulletinManager!.statusBarAppearance = .hidden
        bulletinManager!.showBulletin(above: presentingViewController!)
    }
    
    func showNotificationsOnboarding() {
     
        let notificationPermissions = BulletinDataSource.makeNotitificationsPage()
        bulletinManager = BLTNItemManager(rootItem: notificationPermissions)
        bulletinManager!.backgroundViewStyle = .dimmed
        bulletinManager!.statusBarAppearance = .hidden
        bulletinManager!.showBulletin(above: presentingViewController!)
        
    }
    
    
    // MARK: - MaterialShowcaseDelegate
    
    func showCaseDidDismiss(showcase: MaterialShowcase, didTapTarget: Bool) {


        sequence.showCaseWillDismis()
        if showcase.primaryText == "Als Fahrer" {
             self.showLocationOnboarding()
        }
        print(showcase)
    }
    
    
    
    
    // MARK: - ImagePickerDelegate
    
    func didSelect(image: UIImage?) {
        guard image != nil else {
            return
        }
        hud.show(in: presentingViewController!.view)
        DataManager.shared.updateUserPhoto(imageData: (image!.pngData())!) { (url, error) in
            self.hud.dismiss()
            if error != nil {
                Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self.presentingViewController!)
            }
            
            
            
        }
        
    }
    
    
}
