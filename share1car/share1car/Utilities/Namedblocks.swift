//
//  Namedblocks.swift
//  share1car
//
//  Created by Alex Linkov on 11/4/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import Foundation
import CoreLocation

public typealias id_error_block = (Any?, Error?) -> Swift.Void
public typealias coordinate_didCancel_block = (CLLocationCoordinate2D?, Bool?) -> Swift.Void
