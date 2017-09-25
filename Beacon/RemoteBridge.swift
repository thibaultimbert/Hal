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
import Alamofire
import SwiftyJSON

class RemoteBridge: EventDispatcher
{
    public var bloodSamples: [BGSample] = []
    public static var TOKEN: String!
    private static var LOGIN_URL: String = "https://share1.dexcom.com/ShareWebServices/Services/General/LoginPublisherAccountByName"
    private var dataTask: URLSessionDataTask?
    
    private static var sharedRemoteBridge: RemoteBridge =
    {
        let bridge = RemoteBridge()
        return bridge
    }()
    
    // authenticates the user to the dexcom REST APIs
    public func login(userName: String, password: String, appID: String = "d8665ade-9673-4e27-9ff6-92db4ce13d13")
    {
        let parameters: Parameters = [
            "accountName": userName,
            "applicationId": appID,
            "password": password
        ]
        
        Alamofire.request(RemoteBridge.LOGIN_URL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            
            if (response.result.isSuccess)
            {
                if let json = response.result.value
                {
                    RemoteBridge.TOKEN = json as! String
                    DispatchQueue.main.async(execute: {
                        self.dispatchEvent(event: Event(type: EventType.loggedIn, target: self))
                    })
                }
            }
        }
    }
    
    // retrieves the user last 24 hours glucose levels
    public func getGlucoseValues (token: String = RemoteBridge.TOKEN, completionHandler: ((UIBackgroundFetchResult) -> Void)! = nil)
    {
        let DATA_URL = "https://share1.dexcom.com/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues?sessionId="+token+"&minutes=1440&maxCount=288"
        
        Alamofire.request(DATA_URL, method: .post).responseJSON { response in
            
            if (response.result.isSuccess) {
                if response.result.value != nil {
                    let data = JSON(data: response.data!)
                    self.bloodSamples.removeAll()
                    for (_,subJson):(String, JSON) in data
                    {
                        if subJson["Value"] != JSON.null && subJson["ST"] != JSON.null && subJson["Trend"] != JSON.null
                        {
                            let value = subJson["Value"].int
                            let date = subJson["ST"].stringValue
                            let trend = subJson["Trend"].int
                            let timeStamp = date.components(separatedBy: "(")[1].components(separatedBy: ")")[0].components(separatedBy: "-")[0]
                            let convertedTime: Int = Int(timeStamp)!/1000
                            //self.bloodSamples.append(BGSample(pValue: value!, pDate: date, pTime: convertedTime, pTrend: trend!))
                        }
                    }
                    
                    if (completionHandler) != nil
                    {
                        completionHandler(.newData)
                    }
                    
                    DispatchQueue.main.async(execute:
                        {
                        if ( self.bloodSamples.count > 0 )
                        {
                            self.dispatchEvent(event: Event(type: EventType.bloodSamples, target: self))
                        } else
                        {
                            self.dispatchEvent(event: Event(type: EventType.glucoseIOError, target: self))
                        }
                    })
                }
            } else
            {
                DispatchQueue.main.async(execute: {
                    self.dispatchEvent(event: Event(type: EventType.glucoseIOError, target: self))
                })
            }
        }
    }
    
    class func shared() -> RemoteBridge
    {
        return sharedRemoteBridge
    }
}

