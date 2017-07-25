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

class DexcomBridge: EventDispatcher{
    
    public var bloodSamples: [BGSample] = []
    public static var TOKEN: String = ""
    private static var LOGIN_URL: String = "https://share1.dexcom.com/ShareWebServices/Services/General/LoginPublisherAccountByName"
    
    public func login() {
        let dict = ["accountName": "thibaultimbert", "applicationId":"d8665ade-9673-4e27-9ff6-92db4ce13d13","password": "9f9d51bc"] as [String: Any]
            var request = URLRequest(url: URL(string: DexcomBridge.LOGIN_URL)!)
            request.httpMethod = "POST"
            request.httpBody = try! JSONSerialization.data(withJSONObject: dict, options: [])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            URLSession.shared.dataTask(with:request, completionHandler: {(data, response, error) in
                if error != nil {
                    print(error as Any)
                } else {
                    do {
                        if let string = String(data: data!, encoding: .utf8) {
                            let parsedToken = string.replacingOccurrences(of: "\"", with: "", options: .literal, range: nil)
                            DexcomBridge.TOKEN = parsedToken
                            self.dispatchEvent(event: Event(type: EventType.loggedIn, target: self))
                        } else {
                            print("not a valid UTF-8 sequence")
                        }
                    }
                }
        }).resume()
    }
    
    public func getGlucoseValues (token: String) {
        let url = "https://share1.dexcom.com/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues?sessionId="+token+"&minutes=1440&maxCount=288"
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with:request, completionHandler: {(data, response, error) in
            if error != nil {
                print(error as Any)
            } else {
                do {
                    
                    guard let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [Any] else {
                        print ("error trying to convert data to JSON")
                        return
                    }
                    for sample in json! {
                        if let bloodSample = sample as? [String: AnyObject] {
                            if let value = bloodSample["Value"] as? Double, let date = bloodSample["ST"] as? String, let trend = bloodSample["Trend"] as? Float {
                                let timeStamp = date.components(separatedBy: "(")[1].components(separatedBy: ")")[0].components(separatedBy: "-")[0]
                                let convertedTime: Int = Int(timeStamp)!/1000
                                self.bloodSamples.append(BGSample(pValue: Int(value), pTime: convertedTime, pTrend: Int(trend)))
                            }
                        }
                    }
                    self.dispatchEvent(event: Event(type: EventType.bloodSamples, target: self))
                }
            }
        }).resume()
    }
    
    public func getGlucoseValues2 (token: String, completion: @escaping (UIBackgroundFetchResult) -> Void) {
        let url = "https://share1.dexcom.com/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues?sessionId="+token+"&minutes=1440&maxCount=288"
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with:request, completionHandler: {(data, response, error) in
            if error != nil {
                print(error as Any)
            } else {
                do {
                    
                    guard let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [Any] else {
                        print ("error trying to convert data to JSON")
                        return
                    }
                    for sample in json! {
                        if let bloodSample = sample as? [String: AnyObject] {
                            if let value = bloodSample["Value"] as? Double, let date = bloodSample["ST"] as? String, let trend = bloodSample["Trend"] as? Float {
                                let timeStamp = date.components(separatedBy: "(")[1].components(separatedBy: ")")[0].components(separatedBy: "-")[0]
                                let convertedTime: Int = Int(timeStamp)!/1000
                                self.bloodSamples.append(BGSample(pValue: Int(value), pTime: convertedTime, pTrend: Int(trend)))
                            }
                        }
                    }
                    completion(UIBackgroundFetchResult.newData)
                    self.dispatchEvent(event: Event(type: EventType.bloodSamples, target: self))
                }
            }
        }).resume()
    }

}
