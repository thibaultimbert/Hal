//
//  Settings.swift
//  Hal
//
//  Created by Thibault Imbert on 9/8/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import UIKit
import Lottie

class SettingsController: UIViewController
{
    private var animationView: LOTAnimationView!
    private var toggle: DarwinBoolean = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        animationView = LOTAnimationView(name: "hamburger")
        animationView.contentMode = .scaleAspectFill
        animationView.frame = CGRect(x: -40, y: -20, width: 130, height: 130)
        animationView.isUserInteractionEnabled = true
        self.view.addSubview(animationView)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleMenu(recognizer:)))
        animationView.addGestureRecognizer(tapRecognizer)
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    func toggleMenu(recognizer: UITapGestureRecognizer) {
        DispatchQueue.main.async(execute:
            {
                self.animationView.play(fromProgress: 0.5, toProgress: 0, withCompletion: { (complete: Bool) in
                    // Now the animation has finished and our image is displayed on screen
                    self.performSegue(withIdentifier: "SettingsToMain", sender: self)
                })
        })
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}
