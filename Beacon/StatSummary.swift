//
//  StatSummary.swift
//  Hal
//
//  Created by Thibault Imbert on 10/7/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import UIKit
import SwiftSVG

class StatSummary: UIView {
    
    var label: UILabel!
    var imageView: UIImageView!
    var image: UIImage!
    
    override init(frame: CGRect){
        super.init(frame: frame)
        imageView  = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 28))
        self.addSubview(imageView)
        let detailsFont = UIFont(name: ".SFUIText-Semibold", size :14)
        label = UILabel(frame: CGRect(x: 30, y: 4, width: 200, height: 21))
        label.textColor = UIColor.white
        label.font = detailsFont
        self.addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initialize (icon: String, text: String, offsetX: Int, offsetY: Int, width: Int, height: Int){
        image = UIImage(named: icon)!
        imageView.frame = CGRect(x: offsetX, y: offsetY, width: width, height: height)
        imageView.image = image
        label.text = text
    }
}
