//
//  DexcomBridge.swift
//  Hal
//
//  Created by Thibault Imbert on 9/22/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import Alamofire
import SwiftyJSON

class DexcomBridge: EventDispatcher
{
    public var bloodSamples: [GlucoseSample] = []
    public static var TOKEN: String!
    public static var REFRESH_TOKEN: String!
    private static var TOKEN_URL: String = "https://sandbox-api.dexcom.com/v1/oauth2/token"
    private static var GLUCOSE_URL: String = "https://sandbox-api.dexcom.com/v1/users/self/egvs"
    private var dataTask: URLSessionDataTask?
    
    private static var sharedDexcomBridge: DexcomBridge =
    {
        let bridge = DexcomBridge()
        return bridge
    }()
    
    // authenticates the user to the dexcom REST APIs
    public func getToken(code: String)
    {
        let parameters: Parameters = [
            "client_secret": "sAWUZwCSmdoeWlyW",
            "client_id": "PufsQSdRKnVgCc8phv3CtKrg7gArPHJT",
            "code": code,
            "grant_type":"authorization_code",
            "redirect_uri":"com.beacon-app.scout"
        ]
        
        let headers: HTTPHeaders = [
            "content-type": "application/x-www-form-urlencoded",
            "cache-control": "no-cache"
        ]
        
        Alamofire.request(DexcomBridge.TOKEN_URL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: headers).responseJSON { response in
            
            if (response.result.isSuccess)
            {
                let result: JSON = JSON(data: response.data!)
                let token: String = result["access_token"].stringValue
                let refreshToken: String = result["refresh_token"].stringValue
                DexcomBridge.TOKEN = token
                DexcomBridge.REFRESH_TOKEN = refreshToken
                DispatchQueue.main.async(execute:
                {
                    self.dispatchEvent(event: Event(type: EventType.token, target: self))
                })
            }
        }
    }
    
    // authenticates the user to the dexcom REST APIs
    public func refreshToken(refreshCode: String = DexcomBridge.REFRESH_TOKEN)
    {
        let parameters: Parameters = [
            "client_secret": "sAWUZwCSmdoeWlyW",
            "client_id": "PufsQSdRKnVgCc8phv3CtKrg7gArPHJT",
            "refresh_token": refreshCode,
            "grant_type":"refresh_token",
            "redirect_uri":"com.beacon-app.scout"
        ]
        
        let headers: HTTPHeaders = [
            "content-type": "application/x-www-form-urlencoded",
            "cache-control": "no-cache"
        ]
        
        Alamofire.request(DexcomBridge.TOKEN_URL, method: .post, parameters: parameters, encoding: URLEncoding.default, headers: headers).responseJSON { response in
            
            if (response.result.isSuccess)
            {
                let result: JSON = JSON(data: response.data!)
                let token: String = result["access_token"].stringValue
                let refreshToken: String = result["refresh_token"].stringValue
                DexcomBridge.TOKEN = token
                DexcomBridge.REFRESH_TOKEN = refreshToken
                DispatchQueue.main.async(execute:
                    {
                        self.dispatchEvent(event: Event(type: EventType.refreshToken, target: self))
                })
            }
        }
    }
    
    // retrieves the user last 24 hours glucose levels
    public func getGlucoseValues (token: String = DexcomBridge.TOKEN, completionHandler: ((UIBackgroundFetchResult) -> Void)! = nil)
    {
        let headers: HTTPHeaders = [
            "authorization": "Bearer " + DexcomBridge.TOKEN
        ]
        
        Alamofire.request(DexcomBridge.GLUCOSE_URL+"?startDate=2017-06-20T08:00:00&endDate=2017-06-27T20:00:00", method: .get, headers: headers).responseJSON { response in
            
            if (response.result.isSuccess) {
                let result: JSON = JSON(data: response.data!)
                self.bloodSamples.removeAll()
                let egvs = result["egvs"].array
                for item:JSON in egvs!
                {
                    if item["value"] != JSON.null && item["systemTime"] != JSON.null && item["trend"] != JSON.null
                    {
                        let value = item["value"].int!
                        let dateTime = item["systemTime"].stringValue
                        let trend = item["trend"].stringValue
                        let date = dateTime.components(separatedBy: "T")[0]
                        let time = dateTime.components(separatedBy: "T")[1]
                        self.bloodSamples.append(GlucoseSample(pValue: value, pDate: date, pTime: time, pTrend: trend))
                    }
                }
                
                DispatchQueue.main.async(execute:
                    {
                        if ( self.bloodSamples.count > 0 )
                        {
                            self.dispatchEvent(event: Event(type: EventType.glucoseValues, target: self))
                        } else
                        {
                            self.dispatchEvent(event: Event(type: EventType.glucoseIOError, target: self))
                        }
                })
                
                if (completionHandler) != nil
                {
                    completionHandler(.newData)
                }
            } else
            {
                DispatchQueue.main.async(execute: {
                    self.dispatchEvent(event: Event(type: EventType.glucoseIOError, target: self))
                })
            }
        }
    }
    
    class func shared() -> DexcomBridge
    {
        return sharedDexcomBridge
    }
}
