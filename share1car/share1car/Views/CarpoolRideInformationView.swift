//
//  CarpoolRideInformationView.swift
//  share1car
//
//  Created by Alex Linkov on 11/11/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import BadgeSwift

class CarpoolRideInformationView: UIView {
    
    var priceText: String?
    var mainTitleText: String?
    var subtitleText: String?
    var photoURL: String?
    
    @IBOutlet weak var priceLabel: BadgeSwift!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!

    override func awakeFromNib() {

        self.imageView.layer.cornerRadius = 60
        self.imageView.layer.masksToBounds = true


    }
    
    func setup(title: String, subtitle: String, photoURL: String, priceText: String) {
        self.priceText = priceText
        mainTitleText = title
        subtitleText = subtitle
        self.photoURL = photoURL
        
        priceLabel.text = self.priceText
        mainLabel.text = mainTitleText
        subtitleLabel.text = subtitleText
        self.imageView.sd_setImage(with: URL.init(string: self.photoURL!)!, placeholderImage: nil)
    }
    

    
    


}
