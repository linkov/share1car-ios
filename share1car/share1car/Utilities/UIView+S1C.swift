//
//  UIView+S1C.swift
//  share1car
//
//  Created by Alex Linkov on 11/14/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import Foundation
import UIKit

extension UIView {

    func addLightShadow () {
        
        layer.shadowOpacity = 0.10
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 7
        layer.shadowOffset = CGSize(width: 0, height: 7)
    }
}
