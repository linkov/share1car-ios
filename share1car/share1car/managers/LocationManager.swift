//
//  LocationManager.swift
//  share1car
//
//  Created by Alex Linkov on 11/5/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    var currentLocationBlock: current_location_block?
    var permissionRequestResult: location_permission_block?
    let manager = CLLocationManager()
    static let shared = LocationManager()
    

     override init(){
         
    }
    
    func findUserLocation(currentLocation: @escaping current_location_block) {
         manager.delegate = self
        currentLocationBlock = currentLocation
        manager.startUpdatingLocation()
        
    }
    
    func requestLocationPermissions(didReceivePermission: @escaping location_permission_block) {
        
        manager.delegate = self
        permissionRequestResult = didReceivePermission
        manager.requestWhenInUseAuthorization()
    }
    
    func validCoordinates(coord: CLLocationCoordinate2D) -> Bool {
        
        let latValid = coord.latitude < 90 && coord.latitude > -90
        let longValid = coord.longitude < 90 && coord.longitude > -90
        
        return latValid && longValid
    }
    
    func locationEnabled() -> Bool {
        
        if !CLLocationManager.locationServicesEnabled() {
            return false
        }
        
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus != .authorizedWhenInUse && authorizationStatus != .authorizedAlways {
            return false
        }
               

        return true
    }
    

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if currentLocationBlock != nil {
            manager.stopUpdatingLocation()
            currentLocationBlock!(CLLocationCoordinate2D(latitude: (locations.last?.coordinate.latitude)!, longitude: (locations.last?.coordinate.longitude)! ))
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if (permissionRequestResult != nil) {
            permissionRequestResult!(locationEnabled())
        }
        
        
    }


}
