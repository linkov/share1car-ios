//
//  RequestUpdateBadgeView.swift
//  share1car
//
//  Created by Alex Linkov on 12/10/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import Spring

class RequestUpdateBadgeView: SpringView {

    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    class func instanceFromNib() -> RequestUpdateBadgeView {
        return UINib(nibName: "RequestUpdateBadgeView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! RequestUpdateBadgeView
    }
    
    override func awakeFromNib() {
        
        self.layer.cornerRadius = 30
//        self.layer.masksToBounds = true
        
        self.actionButton.layer.cornerRadius = 6
        self.actionButton.addTarget(self, action: #selector(removeSelf), for: .touchUpInside)
       
        self.addLightShadow()

    }
    
    override var safeAreaLayoutGuide: UILayoutGuide {
        return UILayoutGuide()
    }
    
    
    @objc func removeSelf() {
        self.animation = "fadeOut"
        self.animate()
    }

}
