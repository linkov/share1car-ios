//
//  UserSettingsProfilePhotoHeaderView.swift
//  share1car
//
//  Created by Alex Linkov on 11/11/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import SDWebImage

class UserSettingsProfilePhotoHeaderView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override func awakeFromNib() {
        
        self.imageView.layer.cornerRadius = 50
        self.imageView.layer.masksToBounds = true
        
        
        let imageRef = DataManager.shared.profilePicFirebaseReference()
        guard imageRef != nil else {
            return
        }
        
        self.imageView.sd_setImage(with: imageRef!, placeholderImage: nil)
    }

}
