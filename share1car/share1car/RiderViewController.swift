//
//  RiderViewController.swift
//  share1car
//
//  Created by Alex Linkov on 11/1/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import Mapbox


import MapboxGeocoder
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation


import Loaf
import BLTNBoard

import JGProgressHUD

class RiderViewController: UIViewController, MGLMapViewDelegate, NavigationMapViewDelegate, ImagePickerDelegate {

    
    @IBOutlet weak var mapView: NavigationMapView!
    
    var imagepicker: ImagePicker?
    let hud = JGProgressHUD(style: .light)
    var bulletinManager: BLTNItemManager?
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        

        imagepicker = ImagePicker(presentationController: self, delegate: self)
        
        setupRiderMap()
        CarpoolManager.shared.configure(mapView: mapView, presentingViewController: self)
       
        
    }
    

    
    override func viewDidAppear(_ animated: Bool) {
        
    
        if (!LocationManager.shared.locationEnabled()) {
            
            showLocationOnboarding()
            
        } else {
            
            mapView.showsUserLocation = true
            
        }
        
    }
    
    
    func showLocationOnboarding() {
        
        let locationPermissions = BulletinDataSource.makeLocationPage()
        locationPermissions.actionHandler = { (item: BLTNActionItem) in
            
            LocationManager.shared.requestLocationPermissions { (didGetPermission) in
                locationPermissions.manager?.dismissBulletin()
                self.mapView.showsUserLocation = true
            }

        }
        bulletinManager = BLTNItemManager(rootItem: locationPermissions)
        bulletinManager!.backgroundViewStyle = .dimmed
        bulletinManager!.statusBarAppearance = .hidden
        bulletinManager!.showBulletin(above: self)
    }
    
    func showProfilePicOnboarding() {
        
        let profilePic = BulletinDataSource.makeProfilePicRequestPage()
        profilePic.actionHandler = { (item: BLTNActionItem) in

            profilePic.manager?.dismissBulletin()
            self.imagepicker?.present(from: self.view)
        }
        bulletinManager = BLTNItemManager(rootItem: profilePic)
        bulletinManager!.backgroundViewStyle = .dimmed
        bulletinManager!.statusBarAppearance = .hidden
        bulletinManager!.showBulletin(above: self)
    }
    
    func showNotificationsOnboarding() {
     
        let notificationPermissions = BulletinDataSource.makeLocationPage()
        bulletinManager = BLTNItemManager(rootItem: notificationPermissions)
        bulletinManager!.backgroundViewStyle = .dimmed
        bulletinManager!.statusBarAppearance = .hidden
        bulletinManager!.showBulletin(above: self)
        
    }
    
    
    func setupRiderMap() {
    
        mapView.delegate = self
        mapView.navigationMapViewDelegate = self
        
        mapView.setZoomLevel(14, animated: false)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gesture.numberOfTouchesRequired = 1
        mapView.addGestureRecognizer(gesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(doubleTapGesture)
        
        gesture.require(toFail: doubleTapGesture)
        
    }
    

    
    

    
    
    // MARK: - Actions
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        if (!AuthManager.shared.isLoggedIn()) {
            AuthManager.shared.presentAuthUIFrom(controller: self)
            return
        }
        
        
        
        if (UserSettingsManager.shared.getUserImageURL() == nil) {
            showProfilePicOnboarding()
            return
        }
        
        let spot = gesture.location(in: mapView)
        guard let location = mapView?.convert(spot, toCoordinateFrom: mapView) else { return }
         
        CarpoolManager.shared.findCarpool(currentLocation: mapView.userLocation!.coordinate, dropOffLocation: location)
        print(location)

    }
    
    
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        

    }
    

    
    // MARK: - ImagePickerDelegate
    
    func didSelect(image: UIImage?) {
        guard image != nil else {
            return
        }
        hud.show(in: self.view)
        DataManager.shared.updateUserPhoto(imageData: (image!.pngData())!) { (url, error) in
            self.hud.dismiss()
            if error != nil {
                Alerts.systemErrorAlert(error: error!.localizedDescription, inController: self)
            }
            
            
            
        }
        
    }

    
    // MARK: - NavigationMapViewDelegate
    
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        
    }
    
    
    
    
     // MARK: - MGLMapViewDelegate
    

    
    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        
        self.mapView.setCenter(self.mapView.userLocation!.coordinate, zoomLevel: 12, animated: false)
    }
    

    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
     
        // For better performance, always try to reuse existing annotations.
        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: "driverLocationItem")
         
        // If there is no reusable annotation image available, initialize a new one.
        if(annotationImage == nil) {
            annotationImage = MGLAnnotationImage(image: UIImage(named: "driverLocationItem")!, reuseIdentifier: "driverLocationItem")
        }
         
        return annotationImage
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {

        return true
    }
     
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {

    }

}
