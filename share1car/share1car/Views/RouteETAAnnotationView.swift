//
//  RouteETAAnnotationView.swift
//  share1car
//
//  Created by Alex Linkov on 11/14/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import Mapbox

class RouteETAAnnotationView: MGLAnnotationView {
    
    var etaText: String?
    
    @IBOutlet weak var ETALabel: UILabel!

    
    func setup(eta: String) {
        ETALabel.text = eta
        
        layer.opacity = 0.8
        addLightShadow()
    }

    

}
