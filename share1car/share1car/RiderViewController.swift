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


import JGProgressHUD

class RiderViewController: UIViewController, MGLMapViewDelegate, NavigationMapViewDelegate {

    
    @IBOutlet weak var mapView: NavigationMapView!
    
    let hud = JGProgressHUD(style: .light)
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        setupRiderMap()
       
         OnboardingManager.shared.changePresentingViewController(viewController: self)
        

    }
    

    override func viewWillAppear(_ animated: Bool) {
        
       
        OnboardingManager.shared.showOnAppOpenOnboarding(mapView: mapView)
        
            if (LocationManager.shared.locationEnabled()) {
                
                mapView.showsUserLocation = true
                
                LocationManager.shared.findUserLocation { (coord) in
                    
                    self.mapView.setCenter(coord, zoomLevel: 12, animated: false)
                }
            }
        
         CarpoolSearchManager.shared.configureAndStartSubscriptions(mapView: mapView, presentingViewController: self)
        
    }



    @objc func handleKeyWindowDidBecomeAvailableAfterLaunch(_ notification:Notification) {
        
        OnboardingManager.shared.changePresentingViewController(viewController: self)
        OnboardingManager.shared.showOnAppOpenOnboarding(mapView: mapView)
        
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
        
  

        
        
        let shouldReturn = OnboardingManager.shared.showOnMapTapOnboardingReturning(mapView: mapView)
        
        if (shouldReturn) {
            return
        }
        
        let spot = gesture.location(in: mapView)
        guard let location = mapView?.convert(spot, toCoordinateFrom: mapView) else { return }
        
        hud.show(in: self.view)
        CarpoolSearchManager.shared.findCarpool(currentLocation: mapView.userLocation!.coordinate, destination: location, didSendRequest: { result, errorString in
            
            self.hud.dismiss()
            
            if errorString != nil {
                Loaf(errorString!, state: .warning, sender: self).show()
            } else {
                Loaf("We have sent request to the driver", state: .info, sender: self).show()
            }
            
            
        })

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
