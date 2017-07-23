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
        
        /*
        details.layer.shadowColor = UIColor.black.cgColor
        details.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
        details.layer.shadowOpacity = 1.0
        details.layer.shadowRadius = 1.0
        details.layer.backgroundColor = UIColor.clear.cgColor
        */
        
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
            
            var comp = Utils.getDate(unixdate: Int(results[0].time), timezone: "PST")
            let date = String (describing: comp.hour!) + ":" + String (describing: comp.minute!) + ":" + String (describing: comp.second!)
            infos += date + " " + String (describing: results[0].value) + " mg/DL"
            
            // display results
            infos +=  "\nVariation: " + String (round(Math.computeSD(samples: results)))
            infos += "\nAverage: " + String (round(Math.computeAverage(samples: results))) + " mg/dL"
            infos +=  "\nA1C: " + String(round(Math.A1C(samples: results)))
            
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
            
            var circleColors: [UIColor] = []
            let color = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            circleColors.append(color)
            let chartDataSet = LineChartDataSet(values: lineDataEntry, label: "Time")
            
            var xAxisDate = Utils.getCurrentLocalDate()
            xAxisDate.addTimeInterval(TimeInterval(-3600))
            
            let calChart = Calendar.current
            
            var compChart: DateComponents
            for index in 1...3 {
                xAxisDate.addTimeInterval(TimeInterval(-3600))
                compChart = calChart.dateComponents([.hour], from: xAxisDate)
                //print (compChart.hour)
            }
            
            chartDataSet.setCircleColor(UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
            chartDataSet.drawValuesEnabled = false
            chartDataSet.circleRadius = 2.0
            self.myChart.xAxis.drawGridLinesEnabled = false
            self.myChart.rightAxis.drawGridLinesEnabled = false
            self.myChart.leftAxis.drawGridLinesEnabled = false
            self.myChart.leftAxis.drawLabelsEnabled = false
            self.myChart.leftAxis.drawLabelsEnabled = false
            self.myChart.leftAxis.enabled = false
            self.myChart.rightAxis.drawAxisLineEnabled = false
            self.myChart.xAxis.enabled = false
            self.myChart.legend.enabled = false
            self.myChart.chartDescription?.enabled = false
            
            let gradientColors = [UIColor.red.cgColor, UIColor.clear.cgColor, UIColor.clear.cgColor] as CFArray
            let colorLocations: [CGFloat] = [1.0, 0.6, 0.0]
            guard let gradient = CGGradient.init(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: colorLocations) else { print ("gradient error"); return }
            chartDataSet.fill = Fill.fillWithLinearGradient(gradient, angle: 90.0)
            chartDataSet.drawFilledEnabled = true
            
            let chartData = LineChartData()
            //chartDataSet.colors = ChartColorTemplates.colorful()
            chartData.addDataSet(chartDataSet)
            self.myChart.xAxis.labelPosition = .bottom
            self.myChart.xAxis.labelTextColor = UIColor.white
            self.myChart.rightAxis.labelTextColor = UIColor.white
            self.myChart.data = chartData
            self.myChart.animate(xAxisDuration: 2.0, yAxisDuration: 2.0, easingOption: .easeInBounce)
            let ll = ChartLimitLine(limit: 150.0)
            ll.lineColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.2)
            let bl = ChartLimitLine(limit: 70)
            self.myChart.rightAxis.addLimitLine(ll)
            self.myChart.rightAxis.addLimitLine(bl)

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
            
            print ( infos )
            
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
