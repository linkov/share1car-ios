//
//  DriverDataManager.swift
//  share1car
//
//  Created by Alex Linkov on 11/4/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation


class DriverDataManager: NSObject {
    
    static let shared = DriverDataManager()
    var ref: DatabaseReference!

     override init(){
        ref = Database.database().reference()
    }
    
    func addDriverRoute(route: Route, driverID: String) {
        self.ref.child("DriverRoutes").child(driverID).setValue(route.json);
    }
    
    func removeDriverRoute(route: Route, driverID: String) {
        self.ref.child("DriverRoutes").child(driverID).removeValue();
    }
    
    func updateNavigation(location: CLLocationCoordinate2D, driverID: String) {
        self.ref.child("RiderLocations").child(driverID).setValue([location.latitude, location.longitude])
    }
}
