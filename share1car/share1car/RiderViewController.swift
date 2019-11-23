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

import Social

import Loaf
import Spring

import JGProgressHUD


//extension RiderViewController: S1CMainRiderControllerProtocol {
//    var criticalMassButton: SpringButton
//}

class RiderViewController: UIViewController, MGLMapViewDelegate, NavigationMapViewDelegate {

    @IBOutlet weak var criticalMassButton: SpringButton!
    @IBOutlet weak var searchBarContainerView: UIView!
    
    @IBOutlet weak var userLocationButton: UIButton!
    @IBOutlet weak var cancelCarpoolButton: SpringButton!
    @IBOutlet weak var mapView: NavigationMapView!
    
    let hud = JGProgressHUD(style: .light)
    var resultSearchController: UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        cancelCarpoolButton.layer.cornerRadius = 22
        userLocationButton.layer.cornerRadius = 22
        criticalMassButton.layer.cornerRadius = 22
        userLocationButton.addLightShadow()
        criticalMassButton.addLightShadow()
        
        setupRiderMap()
        setupSearch()
        CarpoolSearchManager.shared.configureAndStartSubscriptions(mapView: mapView, presentingViewController: self)
        
        DataManager.shared.getTotalUserCount { (res, errorString) in
            if errorString != nil {
                Alerts.systemErrorAlert(error: errorString!, inController: self)
                return
            }
            
            self.criticalMassButton.setTitle("Only \(res as! Int) users. Help!", for: .normal)
            self.criticalMassButton.animate()
            
            
        }
    }
    


        override func viewDidAppear(_ animated: Bool) {
        
            OnboardingManager.shared.changePresentingViewController(viewController: self)
            
            let shouldReturn = OnboardingManager.shared.showOnAppOpenOnboardingReturning(mapView: mapView)
            if (shouldReturn) {
                return
            }
        
            if (LocationManager.shared.locationEnabled()) {
                
                mapView.showsUserLocation = true
                
                LocationManager.shared.findUserLocation { (coord) in
                        
                        self.mapView.setCenter(coord, zoomLevel: 12, animated: false)
                    }
                }
      }



//    @objc func handleKeyWindowDidBecomeAvailableAfterLaunch(_ notification:Notification) {
//
//        OnboardingManager.shared.changePresentingViewController(viewController: self)
//        OnboardingManager.shared.showOnAppOpenOnboarding(mapView: mapView)
//        
//    }

    
    
    func toggleCancelCarpoolButton(active: Bool) {
        
        if (active) {
            cancelCarpoolButton.animation = "fadeInUp"
            cancelCarpoolButton.animate()
            
        } else {
            cancelCarpoolButton.animation = "fadeOut"
            cancelCarpoolButton.animate()
        }
        
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
    

    
    func setupSearch() {
        
        let locationSearchTVC = storyboard!.instantiateViewController(withIdentifier: "SearchTableViewController") as! SearchTableViewController
        resultSearchController = UISearchController(searchResultsController: locationSearchTVC)
        resultSearchController!.searchResultsUpdater = locationSearchTVC as UISearchResultsUpdating
        resultSearchController!.searchBar.placeholder = "Search for places"
        resultSearchController!.searchBar.addLightShadow()
        searchBarContainerView.addSubview(resultSearchController!.searchBar)
        
        searchBarContainerView.layer.cornerRadius = 22
        searchBarContainerView.clipsToBounds = true
        
        resultSearchController!.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        locationSearchTVC.currentUserLocation = mapView.userLocation
        locationSearchTVC.completion = { (location, didCancel) in
            

            self.resultSearchController?.dismiss(animated: true, completion: nil)
            self.findCarpool(location: location!)
            
        }
    }

    
    func findCarpool(location: CLLocationCoordinate2D) {
        
        hud.show(in: self.view)
        CarpoolSearchManager.shared.findCarpool(currentLocation: mapView.userLocation!.coordinate, destination: location, didSendRequest: { result, errorString in
            
            self.hud.dismiss()
            
            if errorString != nil {
                Loaf(errorString!, state: .warning, sender: self).show()
                return
            }
            
            if result != nil {
                Loaf(result! as! String, state: .success, sender: self).show()
            }
            
           
            
        })
    }
    
    // MARK: - Actions
    
    
    @IBAction func cancelCarpoolDidTap(_ sender: Any) {
        
        self.toggleCancelCarpoolButton(active: false)
        CarpoolSearchManager.shared.cancelCarpool()
    }
    
    @IBAction func criticalMassDidTap(_ sender: Any) {
        
        let logo = UIImage(named: "feedbackLogo")
        
        let share = [logo!, "Share 1 car and save time and planet", URL(string: "https://share1car.de")!] as [Any]
        
        
        hud.show(in: self.view)
        let activityViewController = UIActivityViewController(activityItems: share, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: {
            
            self.hud.dismiss()
        })
        

    }
    
    
    @IBAction func userLocationDidTap(_ sender: Any) {
         
         LocationManager.shared.findUserLocation { (coord) in
             
             self.mapView.setCenter(coord, zoomLevel: 12, animated: true)
         }
         
     }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
  
        
        
        let shouldReturn = OnboardingManager.shared.showOnMapTapOnboardingReturning(mapView: mapView)
        
        if (shouldReturn) {
            return
        }
        
        let spot = gesture.location(in: mapView)
        guard let location = mapView?.convert(spot, toCoordinateFrom: mapView) else { return }
        
        findCarpool(location: location)

    }
    
    
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        

    }
    



    
    // MARK: - NavigationMapViewDelegate
    
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        
    }
    
    
    
     // MARK: - MGLMapViewDelegate
    

    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
     
        var annotationImage = mapView.dequeueReusableAnnotationImage(withIdentifier: "driverLocationItem")
         
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
