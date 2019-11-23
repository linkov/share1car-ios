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

import JGProgressHUD

import AwesomeSpotlightView

class OnboardingManager: NSObject, ImagePickerDelegate, AwesomeSpotlightViewDelegate {
    
    var mapView: NavigationMapView?
    var imagepicker: ImagePicker?
    var completionBlock: didfinish_block?
    
    let hud = JGProgressHUD(style: .light)
    
    var bulletinManager: BLTNItemManager?
    var presentingViewController: UIViewController?
    static let shared = OnboardingManager()
    
    override init(){
        
    }
    
    
    func changePresentingViewController(viewController: UIViewController) {
        imagepicker = ImagePicker(presentationController: viewController as! UIViewController, delegate: self)
        self.presentingViewController = viewController
    }
    
    
    
    func showOnAppOpenOnboardingReturning(mapView: NavigationMapView) -> Bool {
        self.mapView = mapView
        
        if (UserSettingsManager.shared.getUserDidSeeTabBarOverlayOnboadrding() == false) {

            let tabBarVC = self.presentingViewController!.parent as! UITabBarController
            let criticalMassButton = (self.presentingViewController! as! RiderViewController).criticalMassButton
            showTabBarOverlayOnboarding(tabBarVC: tabBarVC, criticalMassButton: criticalMassButton!)
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
    

    func showRiderCarpoolInfoOverlayOnboarding(completionBlock: @escaping didfinish_block) {
        
        self.completionBlock = completionBlock
        
        if (UserSettingsManager.shared.getRiderDidSeeCarpoolOverlayOnboadrding() == false) {
        
            UserSettingsManager.shared.saveRiderDidSeeCarpoolOverlayOnboadrding(didSee: true)
            
            let spotlight1 = AwesomeSpotlight(withRect: CGRect.zero, shape: .circle, text: "You have now selected your destination on the driver's route and can now send a ride request. The first red needle marks the pickup (near your location: there you have to get in), the second red needle marks the dropoff (there you get off). If you want to change the dropoff, click on Cancel and select another destination on the route.", isAllowPassTouchesThroughSpotlight: true)
        
                let spotlight2 = AwesomeSpotlight(withRect: CGRect.zero, shape: .circle, text: "The price is about the fuel costs that you have to refund the driver (currently with cash!). If you agree, you can send a request to the driver now. It is important that you are at pickup time at the time indicated")
        
                let spotlightView = AwesomeSpotlightView(frame: presentingViewController!.view.frame, spotlight: [spotlight1, spotlight2])
                spotlightView.cutoutRadius = 8
                spotlightView.setContinueButtonEnable(true)
                spotlightView.delegate = self
                presentingViewController!.view.addSubview(spotlightView)
                spotlightView.start()
        
        
        } else {
            
            completionBlock(true)
        }
    }
    
    func showCarpoolOverlayOnboarding(carpoolButton: UIButton, plannedCarpoolButton: UIButton) {
        
        if (UserSettingsManager.shared.getDriverDidSeeCarpoolOverlayOnboadrding() == false) {
            UserSettingsManager.shared.saveDriverDidSeeCarpoolOverlayOnboadrding(didSee: true)
            
            let spotlight1 = AwesomeSpotlight(withRect:  carpoolButton.frame, shape: .roundRectangle, text: "To spontaneously offer a carpool (ride), select your destination on the map, sit in the car and start navigation here. You can accept or decline carpool requests while driving.", isAllowPassTouchesThroughSpotlight: true)

        let spotlight2 = AwesomeSpotlight(withRect: plannedCarpoolButton.frame, shape: .roundRectangle, text: "To plan a carpool in advance, you can choose your planned departure time here. This increases the chance that you will find a passenger!")

        let spotlightView = AwesomeSpotlightView(frame: presentingViewController!.view.frame, spotlight: [spotlight1, spotlight2])
        spotlightView.cutoutRadius = 30
        spotlightView.setContinueButtonEnable(true)
        spotlightView.delegate = self
            presentingViewController!.parent!.view.addSubview(spotlightView)
        spotlightView.start()
        
        }


    }
    
    func showTabBarOverlayOnboarding(tabBarVC: UITabBarController, criticalMassButton: UIButton) {
        
        if (UserSettingsManager.shared.getUserDidSeeTabBarOverlayOnboadrding() == true) {
            return
        }
        
        
        let biggerFrameForCriticalMassButton = CGRect(x: criticalMassButton.frame.origin.x - 8, y: criticalMassButton.frame.origin.y - 16, width:  criticalMassButton.frame.width + 16, height: criticalMassButton.frame.height + 16)
        
        let firstFrame = CGRect(x: tabBarVC.tabBar.frame.origin.x, y: tabBarVC.tabBar.frame.origin.y, width: tabBarVC.tabBar.frame.width / 3, height: tabBarVC.tabBar.frame.height)
        let secondFrame = CGRect(x: firstFrame.origin.x + firstFrame.width, y: tabBarVC.tabBar.frame.origin.y, width: tabBarVC.tabBar.frame.width / 3, height: tabBarVC.tabBar.frame.height)
        
        let spotlight1 = AwesomeSpotlight(withRect: firstFrame, shape: .roundRectangle, text: "If a ride is offered (red route on the map), you as a passenger can choose your destination by a short click on the route.", isAllowPassTouchesThroughSpotlight: true)

        let spotlight2 = AwesomeSpotlight(withRect: secondFrame, shape: .roundRectangle, text: "As a driver you can select your destination by a short click on the map or via the search bar.")
        

        
        let spotlight3 = AwesomeSpotlight(withRect: biggerFrameForCriticalMassButton, shape: .roundRectangle, text: "The share1car app works only when there are enough drivers and passengers (so a critical mass is reached). You can actively help make the app known in your area by using this button to share the app with your friends and acquaintances.", isAllowPassTouchesThroughSpotlight: true)


        let spotlightView = AwesomeSpotlightView(frame: presentingViewController!.view.frame, spotlight: [spotlight1, spotlight2, spotlight3])
        
        spotlightView.cutoutRadius = 8
        spotlightView.delegate = self
        tabBarVC.view.addSubview(spotlightView)
        spotlightView.start()
        

        UserSettingsManager.shared.saveUserDidSeeTabBarOverlayOnboadrding(didSee: true)
    }


    
    func showPhoneNumberOnboarding() {
        
        let phoneNumberPage = BulletinDataSource.makeTextFieldPage()
        
        phoneNumberPage.textInputHandler = { (item, text) in
            DataManager.shared.updateUserPhone(userID: AuthManager.shared.currentUserID()!, phoneNumber: text!)
            phoneNumberPage.manager?.dismissBulletin()

        }
        bulletinManager = BLTNItemManager(rootItem: phoneNumberPage)
        bulletinManager!.backgroundViewStyle = .dimmed
        bulletinManager!.statusBarAppearance = .hidden
        bulletinManager!.showBulletin(above: presentingViewController!)
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
    
    
    
    // MARK: - AwesomeSpotlightViewDelegate
    
    func spotlightViewDidCleanup(_ spotlightView: AwesomeSpotlightView) {
        
        if !LocationManager.shared.locationEnabled() {
        
            self.showLocationOnboarding()
        }
        
        if completionBlock != nil {
            completionBlock!(true)
        }
        
        
    }
    
    func spotlightView(_ spotlightView: AwesomeSpotlightView, didNavigateToIndex index: Int) {
        
        
    }
//    func showCaseDidDismiss(showcase: MaterialShowcase, didTapTarget: Bool) {
//
//
//        sequence.showCaseWillDismis()
//        if showcase.primaryText == "Als Fahrer" {
//             self.showLocationOnboarding()
//        }
//        print(showcase)
//    }
//
    
    
    
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
