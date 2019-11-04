//
//  RiderViewController.swift
//  share1car
//
//  Created by Alex Linkov on 11/1/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import Mapbox

class RiderViewController: UIViewController, MGLMapViewDelegate {

    
    @IBOutlet weak var mapView: MGLMapView!
    override func viewDidAppear(_ animated: Bool) {
    
        

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupRiderMap()

    }
    
    func setupRiderMap() {
    
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.setZoomLevel(14, animated: false)
        
    }
    
    
    
     // MARK: - MGLMapViewDelegate
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        
        guard let userLocation = mapView.userLocation else {
            return
        }
        
        mapView.setCenter(userLocation.coordinate, zoomLevel: 12, animated: false)
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {

        return true
    }
     
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {

    }

}
