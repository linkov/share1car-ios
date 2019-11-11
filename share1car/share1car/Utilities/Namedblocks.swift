//
//  Namedblocks.swift
//  share1car
//
//  Created by Alex Linkov on 11/4/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import Foundation
import CoreLocation
import Firebase


public typealias id_error_block = (Any?, Error?) -> Swift.Void
public typealias coordinate_didCancel_block = (CLLocationCoordinate2D?, Bool?) -> Swift.Void

public typealias drivers_locations_block = ([String : Any]) -> Swift.Void
public typealias routes_geometries_block = ([String : String]) -> Swift.Void
public typealias location_permission_block = (Bool) -> Swift.Void
public typealias driver_route_geometry_error_block = (String?, Error?) -> Swift.Void

public typealias userdetails_error_block = (S1CUserDetails?, Error?) -> Swift.Void

public typealias imageurl_error_block = (String?, Error?) -> Swift.Void

public typealias result_errordescription_block = (Any?, String?) -> Swift.Void
