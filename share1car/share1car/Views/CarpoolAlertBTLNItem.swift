//
//  CarpoolAlertBTLNItem.swift
//  share1car
//
//  Created by Alex Linkov on 11/11/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import BLTNBoard

class CarpoolAlertBTLNItem: BLTNPageItem {

    var infoView: CarpoolRideInformationView?
    
    var mainTitle: String?
    var subtitle: String?
    var photoURL: String?
    var priceText: String?
    
    init(topTitle: String,  mainTitle: String, subtitle: String, photoURL: String, priceText: String) {
        super.init(title: topTitle)
        
        self.mainTitle = mainTitle
        self.subtitle = subtitle
        self.photoURL = photoURL
        self.priceText = priceText

    }
    
    override func makeViewsUnderTitle(with interfaceBuilder: BLTNInterfaceBuilder) -> [UIView]? {
        infoView = UINib(nibName: "CarpoolRideInformationView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? CarpoolRideInformationView
        infoView?.setup(title: mainTitle!, subtitle: subtitle!, photoURL: photoURL!, priceText: priceText!)
        let viewWrapper = interfaceBuilder.wrapView(infoView!, width: nil, height: 256, position: .pinnedToEdges)
        return [viewWrapper]
    }
}
