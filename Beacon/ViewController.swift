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
    
    @IBOutlet weak var average: UILabel!
    @IBOutlet weak var a1c: UILabel!
    @IBOutlet weak var sd: UILabel!
    @IBOutlet weak var myLabel: UILabel!
    @IBOutlet weak var highs: UILabel!
    @IBOutlet weak var normal: UILabel!
    @IBOutlet weak var lows: UILabel!
    @IBOutlet weak var currentBG: UILabel!
    @IBOutlet weak var myChart: LineChartView!
    
    public var hkManager: HKManager!
    public var dxBridge: DexcomBridge!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // font setup
        let font = UIFont(name: ".SFUIText-Semibold", size :14)
        let bodyFont = UIFont(name: ".SFUIText-Semibold", size :25)
        
        myLabel.font = font
        average.font = bodyFont
        a1c.font = bodyFont
        sd.font = bodyFont
        highs.font = bodyFont
        normal.font = bodyFont
        lows.font = bodyFont
        currentBG.font = bodyFont
        
        average.text = "Initializing..."
    
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
            
            // display results
            self.sd.text =  "Variation: " + String (round(Math.computeSD(samples: results)))
            self.average.text = "Average: " + String (round(Math.computeAverage(samples: results))) + " mg/dL"
            self.a1c.text =  "A1C: " + String(round(Math.A1C(samples: results)))
            self.currentBG.text = String (describing: results[0].time) + String (describing: results[0].value) + " mg/DL " + String (results[0].trend)
            
            var lineDataEntry: [ChartDataEntry] = [ChartDataEntry]()
            let data: [BGSample] = self.dxBridge.bloodSamples.reversed()
            
            var i: Double = 0
            for sample in data {
                print ( sample.time )
                let sugarLevel = ChartDataEntry(x: i, y: Double(sample.value))
                lineDataEntry.append (sugarLevel)
                i += 1
            }
            
           // self.myChart.animate(xAxisDuration: 2.0, yAxisDuration: 2.0, easing: easeInSine)
            let chartDataSet = LineChartDataSet(values: lineDataEntry, label: "Time")
            let chartData = LineChartData()
            chartData.addDataSet(chartDataSet)
            self.myChart.data = chartData
            
            // calculate distribution
            let highs: [BGSample] = Math.computeHighBG(samples: results)
            let lows: [BGSample] = Math.computeLowBG(samples: results)
            let normal: [BGSample] = Math.computeNormalRangeBG(samples: results)
            
            // percentages
            let highsPercentage : Double = Double (highs.count) / Double (results.count)
            let normalRangePercentage : Double = Double (normal.count) / Double (results.count)
            let lowsPercentage : Double = Double (lows.count) / Double(results.count)

            self.highs.text = "Highs: " + String ( highsPercentage.roundTo(places: 2) * 100 ) + "%"
            self.normal.text = "Normal: " + String ( normalRangePercentage.roundTo(places: 2) * 100 ) + "%"
            self.lows.text = "Lows: " + String ( lowsPercentage.roundTo(places: 2) * 100 ) + "%"

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
