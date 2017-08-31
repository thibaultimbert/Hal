//
//  DetailsViewController.swift
//  Hal
//
//  Created by Thibault Imbert on 8/22/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var password: UITextField!
    public var defaults: UserDefaults!
    public var dxBridge: DexcomBridge!
    private var setupBg: AnimatedBackground!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // background handling
        setupBg = AnimatedBackground (parent: self)
        
        // auth login
        dxBridge = DexcomBridge.shared()
        let loggedIn = EventHandler(function: self.onLoggedIn)
        let authError = EventHandler(function: self.onAuthError)
        dxBridge.addEventListener(type: .loggedIn, handler: loggedIn)
        dxBridge.addEventListener(type: .authLoginError, handler: authError)
        
        // password management
        defaults = UserDefaults.standard
        let userName = defaults.string(forKey: "user")
        let password = defaults.string(forKey: "password")
        
        if userName != nil && password != nil {
            print ( userName!, password!)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func `continue`(_ sender: Any) {
        // test if there is username and password
        if let userName = userName.text, !userName.isEmpty, let password = password.text, !password.isEmpty
        {
            // save username and password
            defaults.set(userName, forKey: "user")
            defaults.set(password, forKey: "password")
            defaults.synchronize()
            // attempt login auth
            dxBridge.login(userName: userName, password: password)
        }
    }
    
    public func onLoggedIn(event: Event){
        // go to the logged in screen
        self.performSegue(withIdentifier: "Main", sender: self)
    }
    
    public func onAuthError(event: Event){
        print ("login problem")
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
