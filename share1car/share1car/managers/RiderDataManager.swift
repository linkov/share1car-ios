//
//  RiderDataManager.swift
//  share1car
//
//  Created by Alex Linkov on 11/7/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation


class RiderDataManager: NSObject {
    
    static let shared = RiderDataManager()
    var ref: DatabaseReference!
    var liveDriversLocations: [String : Any]?

     override init() {
        ref = Database.database().reference()
    }
    
    
    func requestCarpool(driverID: String) {
        
    }
    
    
    func lastLocationForDriver(driverID: String) -> CLLocationCoordinate2D? {
        
        guard liveDriversLocations != nil else {
            return nil
        }
        
        let driverLocations = liveDriversLocations![driverID] as! [Double]
        let latitude = driverLocations[0]
        let longitude =  driverLocations[1]
        
        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        return coordinates
        
        
    }
    
    func getDriversLocationa(updates: @escaping drivers_locations_block) {
        
        
        //TODO: should be DriverLocations
        self.ref.child("RiderLocations").observe(DataEventType.value) { (DataSnapshot) in
            
            let resultDict = DataSnapshot.value as? [String : Any] ?? [:]
            
            self.liveDriversLocations = resultDict
        
            updates(resultDict)
            print(resultDict)

        }
    }
    
    func getAvailableDriverRoutes(updates: @escaping routes_geometries_block) {
        self.ref.child("DriverRoutes").observe(DataEventType.value) { (DataSnapshot) in
            
            let resultDict = DataSnapshot.value as? [String : String] ?? [:]
            
            print(resultDict)
            updates(resultDict)

        }
    }
    
    
}
