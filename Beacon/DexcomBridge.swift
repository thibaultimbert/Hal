//
//  DexcomBridge.swift
//  Hal
//
//  Created by Thibault Imbert on 7/18/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class DexcomBridge: EventDispatcher {
    
    public var bloodSamples: [BGSample] = []
    public static var TOKEN: String = ""
    private static var LOGIN_URL: String = "https://share1.dexcom.com/ShareWebServices/Services/General/LoginPublisherAccountByName"
    private var dataTask: URLSessionDataTask?
    
    private static var sharedDXBridge: DexcomBridge = {
        let dxBridge = DexcomBridge()
        return dxBridge
    }()
    
    // authenticates the user to the dexcom REST APIs
    public func login(userName: String, password: String, appID: String = "d8665ade-9673-4e27-9ff6-92db4ce13d13") {
        let dict = ["accountName": userName, "applicationId": appID,
                    "password": password] as [String: Any]
        var request = URLRequest(url: URL(string: DexcomBridge.LOGIN_URL)!)
        request.httpMethod = "POST"
        request.httpBody = try! JSONSerialization.data(withJSONObject: dict, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        dataTask?.cancel()
        dataTask = URLSession.shared.dataTask(with:request) { data, response, error in
            let response = String(data: data!, encoding: .utf8)
            if let data = response?.data(using: String.Encoding.utf8) {
                do {
                    if let parseJSON = try JSONSerialization.jsonObject(with: data) as? [String:Any] {
                        let errorCode = String(describing: parseJSON["Code"]!)
                        if errorCode == "SSO_AuthenticateAccountNotFound" || errorCode == "SSO_AuthenticatePasswordInvalid" {
                            DispatchQueue.main.async(execute: {
                                self.dispatchEvent(event: Event(type: EventType.authLoginError, target: self))
                            })
                        }
                    }
                } catch _ as NSError {
                    let parsedToken = response?.replacingOccurrences(of: "\"", with: "", options: .literal, range: nil)
                    DexcomBridge.TOKEN = parsedToken!
                    DispatchQueue.main.async(execute: {
                        self.dispatchEvent(event: Event(type: EventType.loggedIn, target: self))
                    })
                }
            } else if let error = error {
                print (error.localizedDescription)
            }
        }
        dataTask?.resume()
    }
    
    // retrieves the user last 24 hours glucose levels
    public func getGlucoseValues (token: String = DexcomBridge.TOKEN, completionHandler: ((UIBackgroundFetchResult) -> Void)! = nil) {
        let DATA_URL = "https://share1.dexcom.com/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues?sessionId="+token+"&minutes=1440&maxCount=288"
        var request = URLRequest(url: URL(string: DATA_URL)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        dataTask?.cancel()
        dataTask = URLSession.shared.dataTask(with:request) { data, response, error in
                do {
                    let response = String(data: data!, encoding: .utf8)
                    if let data = response?.data(using: String.Encoding.utf8) {
                        if let parseJSON = try JSONSerialization.jsonObject(with: data) as? [[String:Any]] {
                        self.bloodSamples.removeAll()
                        for sample in parseJSON {
                            if let value = sample["Value"] as? Double, let date = sample["ST"] as? String, let trend = sample["Trend"] as? Float {
                                let timeStamp = date.components(separatedBy: "(")[1].components(separatedBy: ")")[0].components(separatedBy: "-")[0]
                                let convertedTime: Int = Int(timeStamp)!/1000
                                self.bloodSamples.append(BGSample(pValue: Int(value), pTime: convertedTime, pTrend: Int(trend)))
                            }
                        }
                        if (completionHandler) != nil {
                            completionHandler(.newData)
                        }
                        DispatchQueue.main.async(execute: {
                            self.dispatchEvent(event: Event(type: EventType.bloodSamples, target: self))
                        })
                        }
                    }
                } catch _ as NSError {
                   print("IO_ERROR")
                    DispatchQueue.main.async(execute: {
                            self.dispatchEvent(event: Event(type: EventType.glucoseIOError, target: self))
                })
            }
        }
        dataTask?.resume()
    }
    
    class func shared() -> DexcomBridge {
        return sharedDXBridge
    }
}
