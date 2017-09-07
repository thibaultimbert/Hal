//
//  DetailsViewController.swift
//  Hal
//
//  Created by Thibault Imbert on 8/22/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var userNameTf: UITextField!
    @IBOutlet weak var passwordTf: UITextField!
    @IBOutlet weak var loginLbl: UILabel!
    @IBOutlet weak var passwordLbl: UILabel!
    @IBOutlet weak var errorLbl: UILabel!
    @IBOutlet weak var taglineLbl: UILabel!
    
    public var defaults: UserDefaults!
    public var dxBridge: RemoteBridge!
    private var loggedIn: EventHandler!
    private var setupBg: AnimatedBackground!
    private var keychain:KeychainSwift!
    private var logo: UIImage!
    private var bodyFont:UIFont!
    private var titleFont: UIFont!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Hal logo
        let imageView:UIImageView = UIImageView(image: UIImage(named: "Hal-Logo"))
        imageView.frame = CGRect(x: 100/2, y: (100*0.87)/2, width: 100, height: 100*0.87)
        var center: CGPoint = self.view.center
        center.y -= 200
        imageView.center = center
        self.view.addSubview(imageView)
        
        // font for buttons and labels
        bodyFont = UIFont(name: ".SFUIText-Semibold", size :11)
        titleFont = UIFont(name: ".SFUIText-Semibold", size :26)
        taglineLbl.font = titleFont
        userNameTf.font = bodyFont
        passwordTf.font = bodyFont
        loginLbl.font = bodyFont
        passwordLbl.font = bodyFont
        errorLbl.font = bodyFont
        
        // tagline
        taglineLbl.text = "HAL, your diabetic\ncoach in your pocket."
        
        // load the keychain
        keychain = KeychainSwift.shared()
        
        // background handling
        setupBg = AnimatedBackground (parent: self)
        
        // auth login
        dxBridge = RemoteBridge.shared()
        loggedIn = EventHandler(function: self.onLoggedIn)
        let authError = EventHandler(function: self.onAuthError)
        dxBridge.addEventListener(type: .loggedIn, handler: loggedIn)
        dxBridge.addEventListener(type: .authLoginError, handler: authError)
        
        // password management
        let userName = keychain.get("user")
        let password = keychain.get("password")
        
        if userName != nil && password != nil {
            dxBridge.login(userName: userName!, password: password!)
            userNameTf.text = userName
            passwordTf.text = password
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func `continue`(_ sender: Any) {
        // test if there is username and password
        if let userName = userNameTf.text, !userName.isEmpty, let password = passwordTf.text, !password.isEmpty
        {
            // save username and password
            keychain.set(userName, forKey: "user")
            keychain.set(password, forKey: "password")
            // attempt login auth
            dxBridge.login(userName: userName, password: password)
        }
    }
    
    public func onLoggedIn(event: Event){
        // go to the logged in screen
        self.performSegue(withIdentifier: "Main", sender: self)
        dxBridge.removeEventListener(type: .loggedIn, handler: loggedIn)
    }
    
    public func onAuthError(event: Event){
        errorLbl.text = "Oops, can you double check your username/password?"
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
