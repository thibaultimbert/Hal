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
    @IBOutlet weak var distribution: UILabel!
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
        average.font = bodyFont
        a1c.font = bodyFont
        sd.font = bodyFont
        highs.font = bodyFont
        distribution.font = bodyFont
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
            var comp = Utils.getDate(unixdate: Int(results[0].time), timezone: "PST")
            let date = String (describing: comp.hour!) + ":" + String (describing: comp.minute!) + ":" + String (describing: comp.second!)
            self.currentBG.text = date + " " + String (describing: results[0].value) + " mg/DL " + String (results[0].trend)
            
            var lineDataEntry: [ChartDataEntry] = [ChartDataEntry]()
            let data: [BGSample] = self.dxBridge.bloodSamples.reversed()
            
            var i: Double = 0
            for sample in data {
                let comp = Utils.getDate(unixdate: Int(sample.time), timezone: "PST")
                print ( comp.hour!, comp.minute!, comp.second! )
                let sugarLevel = ChartDataEntry(x: i, y: Double(sample.value))
                lineDataEntry.append (sugarLevel)
                i += 1
            }
            
           // self.myChart.animate(xAxisDuration: 2.0, yAxisDuration: 2.0, easing: easeInSine)
            let chartDataSet = LineChartDataSet(values: lineDataEntry, label: "Time")
            let chartData = LineChartData()
            chartDataSet.colors = ChartColorTemplates.colorful()
            chartData.addDataSet(chartDataSet)
            self.myChart.xAxis.labelPosition = .bottom
            self.myChart.data = chartData
            self.myChart.animate(xAxisDuration: 2.0, yAxisDuration: 2.0, easingOption: .easeInBounce)
            let ll = ChartLimitLine(limit: 150.0, label: "High")
            let bl = ChartLimitLine(limit: 70, label: "Low")
            self.myChart.rightAxis.addLimitLine(ll)
            self.myChart.rightAxis.addLimitLine(bl)

            // calculate distribution
            let highs: [BGSample] = Math.computeHighBG(samples: results)
            let lows: [BGSample] = Math.computeLowBG(samples: results)
            let normal: [BGSample] = Math.computeNormalRangeBG(samples: results)
            
            let averageHigh: Double = Math.computeAverage(samples: highs)
            let averageNormal: Double = Math.computeAverage(samples: normal)
            let averageLow: Double = Math.computeAverage(samples: lows)
            
            self.distribution.text = "Avg/High: " + String(describing: averageHigh.roundTo(places: 2)) + " \nAvg/Normal: " + String(describing: averageNormal.roundTo(places: 2)) + " \nAvg/Low: " + String(describing: averageLow.roundTo(places: 2))
            
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
