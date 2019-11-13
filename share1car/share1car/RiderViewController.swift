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
            
            let shouldReturn = OnboardingManager.shared.showOnAppOpenOnboardingReturning(mapView: mapView)
            if (shouldReturn) {
                return
            }
        

        CarpoolSearchManager.shared.configureAndStartSubscriptions(mapView: mapView, presentingViewController: self)
       
        
    }
    

    override func viewWillAppear(_ animated: Bool) {
        
            if (LocationManager.shared.locationEnabled()) {
                
                mapView.showsUserLocation = true
                
                LocationManager.shared.findUserLocation { (coord) in
                    
                    self.mapView.setCenter(coord, zoomLevel: 12, animated: false)
                }
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
    

    
    

    
    
    // MARK: - Actions
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
  
        
        let shouldReturn = OnboardingManager.shared.showOnMapTapOnboardingReturning(mapView: mapView)
        
        if (shouldReturn) {
            return
        }
        
        let spot = gesture.location(in: mapView)
        guard let location = mapView?.convert(spot, toCoordinateFrom: mapView) else { return }
         
        CarpoolSearchManager.shared.findCarpool(currentLocation: mapView.userLocation!.coordinate, destination: location, didSendRequest: { didSend in
            
            if (didSend) {
               
            }
            
        })
        print(location)

    }
    
    
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        

    }
    



    
    // MARK: - NavigationMapViewDelegate
    
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        
    }
    
    
    
    
    
     // MARK: - MGLMapViewDelegate
    

    
    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        
//        self.mapView.setCenter(self.mapView.userLocation!.coordinate, zoomLevel: 12, animated: false)
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
