//
//  RemoteBridge.swift
//  Hal
//
//  Created by Thibault Imbert on 9/5/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import SwiftyJSON

class RemoteBridge: EventDispatcher {
    
    public var bloodSamples: [BGSample] = []
    public static var TOKEN: String!
    private static var LOGIN_URL: String = "https://share1.dexcom.com/ShareWebServices/Services/General/LoginPublisherAccountByName"
    private var dataTask: URLSessionDataTask?
    
    private static var sharedDXBridge: RemoteBridge = {
        let dxBridge = RemoteBridge()
        return dxBridge
    }()
    
    // authenticates the user to the dexcom REST APIs
    public func login(userName: String, password: String, appID: String = "d8665ade-9673-4e27-9ff6-92db4ce13d13") {
        
        let dict = ["accountName": userName, "applicationId": appID,
                    "password": password] as [String: Any]
        var request = URLRequest(url: URL(string: RemoteBridge.LOGIN_URL)!)
        request.httpMethod = "POST"
        request.httpBody = try! JSONSerialization.data(withJSONObject: dict, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        dataTask?.cancel()
        dataTask = URLSession.shared.dataTask(with:request) { data, response, error in
            do {
                let parsed: String
                if let response = data {
                    parsed = String(data: response, encoding: .utf8)!
                } else {
                    throw NSError()
                }
                if let dataFromString = parsed.data(using: .utf8, allowLossyConversion: false) {
                    let json = JSON(data: dataFromString)
                    if json["Code"] == JSON.null {
                        let parsedToken = parsed.replacingOccurrences(of: "\"", with: "", options: .literal, range: nil)
                        RemoteBridge.TOKEN = parsedToken
                        DispatchQueue.main.async(execute: {
                            self.dispatchEvent(event: Event(type: EventType.loggedIn, target: self))
                        })
                    } else {
                        let errorCode = json["Code"].stringValue
                        if errorCode == "SSO_AuthenticateAccountNotFound" || errorCode == "SSO_AuthenticatePasswordInvalid" {
                            DispatchQueue.main.async(execute: {
                                self.dispatchEvent(event: Event(type: EventType.authLoginError, target: self))
                            })
                        }
                    }
                }
            } catch _ as NSError {
                DispatchQueue.main.async(execute: {
                    self.dispatchEvent(event: Event(type: EventType.glucoseIOError, target: self))
                })
            }
        }
        dataTask?.resume()
    }
    
    // retrieves the user last 24 hours glucose levels
    public func getGlucoseValues (token: String = RemoteBridge.TOKEN, completionHandler: ((UIBackgroundFetchResult) -> Void)! = nil) {
        let DATA_URL = "https://share1.dexcom.com/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues?sessionId="+token+"&minutes=1440&maxCount=288"
        var request = URLRequest(url: URL(string: DATA_URL)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        dataTask?.cancel()
        dataTask = URLSession.shared.dataTask(with:request) { data, response, error in
            do {
                let parsed: String
                if let response = data {
                    parsed = String(data: response, encoding: .utf8)!
                } else {
                    throw NSError()
                }
                if let dataFromString = parsed.data(using: .utf8, allowLossyConversion: false) {
                    let json = JSON(data: dataFromString)
                    self.bloodSamples.removeAll()
                    for (_,subJson):(String, JSON) in json {
                        if subJson["Value"] != JSON.null && subJson["ST"] != JSON.null && subJson["Trend"] != JSON.null {
                            let value = subJson["Value"].int
                            let date = subJson["ST"].stringValue
                            let trend = subJson["Trend"].int
                            let timeStamp = date.components(separatedBy: "(")[1].components(separatedBy: ")")[0].components(separatedBy: "-")[0]
                            let convertedTime: Int = Int(timeStamp)!/1000
                            self.bloodSamples.append(BGSample(pValue: value!, pTime: convertedTime, pTrend: trend!))
                        } else {
                            throw NSError()
                        }
                    }
                    if (completionHandler) != nil {
                        completionHandler(.newData)
                    }
                    DispatchQueue.main.async(execute: {
                        self.dispatchEvent(event: Event(type: EventType.bloodSamples, target: self))
                    })
                }
            } catch _ as NSError {
                DispatchQueue.main.async(execute: {
                    self.dispatchEvent(event: Event(type: EventType.glucoseIOError, target: self))
                })
            }
        }
        dataTask?.resume()
    }
    
    class func shared() -> RemoteBridge {
        return sharedDXBridge
    }
}

