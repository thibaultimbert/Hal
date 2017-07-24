//
//  ViewController.swift
//  HAL
//
//  Created by Thibault Imbert on 7/12/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import UIKit
import HealthKit
import UserNotifications
import Charts

class ViewController: UIViewController {
    
    @IBOutlet weak var myLabel: UILabel!
    @IBOutlet weak var details: UILabel!
    @IBOutlet weak var myChart: LineChartView!
    
    public var hkManager: HKManager!
    public var dxBridge: DexcomBridge!
    private var gradientLayer = CAGradientLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gradientLayer.frame = self.view.bounds
        
        let color1 = UIColor(red: 0.32, green: 0.49, blue: 0.54, alpha: 1.0).cgColor as CGColor
        let color2 = UIColor(red: 0.48, green: 0.65, blue: 0.68, alpha: 1.0).cgColor as CGColor
        let color3 = UIColor(red: 0.63, green: 0.77, blue: 0.74, alpha: 1.0).cgColor as CGColor
        let color4 = UIColor(red: 0.5, green: 0.78, blue: 0.79, alpha: 1.0).cgColor as CGColor
        let color5 = UIColor(red: 0.39, green: 0.64, blue: 0.69, alpha: 1.0).cgColor as CGColor
        gradientLayer.colors = [color1, color2, color3, color4, color5]
        
        gradientLayer.locations = [0.0, 0.12, 0.25, 0.5, 1.0]
        self.view.layer.insertSublayer(gradientLayer, at:0)
        
        // font setup
        let font = UIFont(name: ".SFUIText-Semibold", size :14)
        let bodyFont = UIFont(name: ".SFUIText-Semibold", size :16)
        
        myLabel.font = font
        details.font = bodyFont
        
        details.text = "Initializing..."
    
        // Do any additional setup after loading the view, typically from a nib.
        // initialize the Dexcom bridge
        dxBridge = DexcomBridge()
    
        let DXLoggedIn = EventHandler(function: {
            (event: Event) in
            // get blood glucose levels from Dexcom
            self.dxBridge.getGlucoseValues(token: DexcomBridge.TOKEN)
        })
        let DXBloodSamples = EventHandler(function: {
            (event: Event) in
            
            // reference the result (Array of BGSample)
            let results = self.dxBridge.bloodSamples
            
            var infos: String = ""
            
            let (_, _, sampleDate) = Utils.getDate(unixdate: Int(results[0].time))
            infos += sampleDate + " " + String (describing: results[0].value) + " mg/DL " + results[0].trend
            
            // display results
            infos +=  "\nVariation: " + String (round(Math.computeSD(samples: results)))
            infos += "\nAverage: " + String (round(Math.computeAverage(samples: results))) + " mg/dL"
            infos +=  "\nA1C: " + String(round(Math.A1C(samples: results)))
            
            _ = ChartManager(lineChart: self.myChart, data: self.dxBridge.bloodSamples)
            
            // calculate distribution
            let highs: [BGSample] = Math.computeHighBG(samples: results)
            let lows: [BGSample] = Math.computeLowBG(samples: results)
            let normal: [BGSample] = Math.computeNormalRangeBG(samples: results)
            
            let averageHigh: Double = ceil(Math.computeAverage(samples: highs))
            let averageNormal: Double = ceil(Math.computeAverage(samples: normal))
            let averageLow: Double = ceil(Math.computeAverage(samples: lows))
            
            infos += "\nAvg/High: " + String(describing: averageHigh.roundTo(places: 2)) + " \nAvg/Normal: " + String(describing: averageNormal.roundTo(places: 2)) + " \nAvg/Low: " + String(describing: averageLow.roundTo(places: 2))
            
            // percentages
            let highsPercentage : Double = Double (highs.count) / Double (results.count)
            let normalRangePercentage : Double = Double (normal.count) / Double (results.count)
            let lowsPercentage : Double = Double (lows.count) / Double(results.count)

            infos += "\nHighs: " + String ( highsPercentage.roundTo(places: 2) * 100 ) + "%"
            infos += "\nNormal: " + String ( normalRangePercentage.roundTo(places: 2) * 100 ) + "%"
            infos += "\nLows: " + String ( lowsPercentage.roundTo(places: 2) * 100 ) + "%"
            
            self.details.text = infos
        })
        
        // wait for Dexcom data
        dxBridge.addEventListener(type: .bloodSamples, handler: DXBloodSamples)
        dxBridge.addEventListener(type: .loggedIn, handler: DXLoggedIn)
        
        // login to dexcom apis
        dxBridge.login()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
