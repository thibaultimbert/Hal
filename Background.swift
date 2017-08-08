//
//  Background.swift
//  Hal
//
//  Created by Thibault Imbert on 8/7/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import UIKit

class Background {
    
    private var gradientLayer = CAGradientLayer()
    
    init( parent: UIViewController ){
        
        gradientLayer.frame = parent.view.bounds
        
        let color1 = UIColor(red: 0.32, green: 0.49, blue: 0.54, alpha: 0.1).cgColor as CGColor
        let color2 = UIColor(red: 0.48, green: 0.65, blue: 0.68, alpha: 0.1).cgColor as CGColor
        let color3 = UIColor(red: 0.63, green: 0.77, blue: 0.74, alpha: 0.1).cgColor as CGColor
        let color4 = UIColor(red: 0.5, green: 0.78, blue: 0.79, alpha: 0.3).cgColor as CGColor
        let color5 = UIColor(red: 0.39, green: 0.64, blue: 0.69, alpha: 1.0).cgColor as CGColor
        gradientLayer.colors = [color1, color2, color3, color4, color5]
        
        gradientLayer.locations = [0.0, 0.12, 0.25, 0.5, 1.0]
        
        let filePath = Bundle.main.path(forResource: "rob", ofType: "jpg")
        _ = NSData(contentsOfFile: filePath!)
        
        let image:UIImage = UIImage(contentsOfFile: filePath!)!
        let imageLayer:CALayer = CALayer()
        imageLayer.contents = image.cgImage
        imageLayer.frame = CGRect(x: 0, y: 0, width: 2001, height: 1334)
        parent.view.layer.insertSublayer(imageLayer, at: 0)
        parent.view.layer.insertSublayer(gradientLayer, at: 1)
    }
}
