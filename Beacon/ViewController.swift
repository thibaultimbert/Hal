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
    
    @IBOutlet weak var detailsLeft: UILabel!
    @IBOutlet weak var current: UILabel!
    @IBOutlet weak var news: UILabel!
    @IBOutlet weak var fulltime: UIButton!
    @IBOutlet weak var difference: UILabel!
    @IBOutlet weak var recent: UIButton!
    @IBOutlet weak var myChart: LineChartView!
    
    public var hkManager: HKManager!
    public var dxBridge: DexcomBridge!
    private var gradientLayer = CAGradientLayer()
    private var chartManager: ChartManager!
    private var timer: Timer!
    private var firstTime:DarwinBoolean = true
    private var results: [BGSample]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myChart.noDataText = ""
        recent.alpha = 0
        fulltime.alpha = 0
        
        gradientLayer.frame = self.view.bounds
        
        let color1 = UIColor(red: 0.32, green: 0.49, blue: 0.54, alpha: 0.1).cgColor as CGColor
        let color2 = UIColor(red: 0.48, green: 0.65, blue: 0.68, alpha: 0.1).cgColor as CGColor
        let color3 = UIColor(red: 0.63, green: 0.77, blue: 0.74, alpha: 0.1).cgColor as CGColor
        let color4 = UIColor(red: 0.5, green: 0.78, blue: 0.79, alpha: 0.3).cgColor as CGColor
        let color5 = UIColor(red: 0.39, green: 0.64, blue: 0.69, alpha: 1.0).cgColor as CGColor
        gradientLayer.colors = [color1, color2, color3, color4, color5]
        
        gradientLayer.locations = [0.0, 0.12, 0.25, 0.5, 1.0]
        
        let filePath = Bundle.main.path(forResource: "rob", ofType: "jpg")
        _ = NSData(contentsOfFile: filePath!)
        
        let image:UIImage = UIImage(contentsOfFile: filePath!)!
        let imageLayer:CALayer = CALayer()
        imageLayer.contents = image.cgImage
        imageLayer.frame = CGRect(x: 0, y: 0, width: 2001, height: 1334)
        self.view.layer.insertSublayer(imageLayer, at: 0)
        self.view.layer.insertSublayer(gradientLayer, at: 1)
        
        // font setup
        let font = UIFont(name: ".SFUIText-Semibold", size :18)
        let bodyFont = UIFont(name: ".SFUIText-Semibold", size :11)
        let headerFont = UIFont(name: ".SFUIText-Semibold", size :28)
        let newsFont = UIFont(name: ".SF-Pro-Display-Thin", size :18)
        
        detailsLeft.font = bodyFont
        news.font = newsFont
        current.font = headerFont
        difference.font = font
        fulltime.titleLabel?.font = bodyFont
        recent.titleLabel?.font = bodyFont
        
        news.text = "You are doing great! An increase of 53% in normal levels and dropped your A1C by 0.8%!"
        
        detailsLeft.text = "Initializing..."
        
        // charts UI
        chartManager = ChartManager(lineChart: myChart)
        let selectionHandler = EventHandler(function: onSelection)
        chartManager.addEventListener(type: EventType.selection, handler: selectionHandler)
    
        // Do any additional setup after loading the view, typically from a nib.
        // initialize the Dexcom bridge
        dxBridge = DexcomBridge()
    
        let DXLoggedIn = EventHandler(function: self.onLoggedIn)
        let DXBloodSamples = EventHandler(function: self.onBloodSamples)
        
        // wait for Dexcom data
        dxBridge.addEventListener(type: .bloodSamples, handler: DXBloodSamples)
        dxBridge.addEventListener(type: .loggedIn, handler: DXLoggedIn)
        
        // login to dexcom apis
        dxBridge.login()
    }
    
    public func onBloodSamples(event: Event){
        
        if (firstTime).boolValue{
            firstTime = false
            timer = Timer.scheduledTimer(timeInterval: 360, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        }
        
        // reference the result (Array of BGSample)
        results = self.dxBridge.bloodSamples
        
        // update charts UI
        chartManager.setData(data: results)
        
        let (_, _, sampleDate) = Utils.getDate(unixdate: Int(results[0].time))
        current.text = sampleDate + "\n" + String (describing: results[0].value) + " mg/DL " + results[0].trend
        
        // details UI
        var infosLeft: String = ""
        
        // display results
        infosLeft +=  "\nA1C: " + String(round(Math.A1C(samples: results)))
        infosLeft +=  "\nVariation: " + String (round(Math.computeSD(samples: results)))
        infosLeft += "\nAverage: " + String (round(Math.computeAverage(samples: results))) + " mg/dL"
        
        recent.alpha = 1
        fulltime.alpha = 1
        
        // calculate distribution
        let highs: [BGSample] = Math.computeHighBG(samples: results)
        let lows: [BGSample] = Math.computeLowBG(samples: results)
        let normal: [BGSample] = Math.computeNormalRangeBG(samples: results)
        
        let averageHigh: Double = ceil(Math.computeAverage(samples: highs))
        let averageNormal: Double = ceil(Math.computeAverage(samples: normal))
        let averageLow: Double = ceil(Math.computeAverage(samples: lows))
        
        infosLeft += "\nAvg/High: " + String(describing: averageHigh.roundTo(places: 2)) + " \nAvg/Normal: " + String(describing: averageNormal.roundTo(places: 2)) + " \nAvg/Low: " + String(describing: averageLow.roundTo(places: 2))
        
        // percentages
        let highsPercentage : Double = Double (highs.count) / Double (results.count)
        let normalRangePercentage : Double = Double (normal.count) / Double (results.count)
        let lowsPercentage : Double = Double (lows.count) / Double(results.count)
        
        let highRatio: Double = (24.0 * highsPercentage).roundTo(places: 2)
        infosLeft += "\nHighs: " + String ( highsPercentage.roundTo(places: 2) * 100 ) + "%"
        infosLeft += " "+String(describing: highRatio) + " hours total"
        let normalRatio: Double = (24.0 * normalRangePercentage).roundTo(places: 2)
        infosLeft += "\nNormal: " + String ( normalRangePercentage.roundTo(places: 2) * 100 ) + "%"
        infosLeft += " "+String(describing: normalRatio) + " hours total"
        let lowRatio: Double = (24.0 * lowsPercentage).roundTo(places: 2)
        infosLeft += "\nLows: " + String ( lowsPercentage.roundTo(places: 2) * 100 ) + "%"
        infosLeft += " "+String(describing: lowRatio) + " hours total"
        
        detailsLeft.text = infosLeft
    }
    
    public func onSelection(event: Event){
        let (_, _, sampleDate) = Utils.getDate(unixdate: Int(chartManager.selectedSample.time))
        let position: Int = chartManager.position
        if ( position > 0 ) {
            let delta: Int = chartManager.samples[position].value - chartManager.samples[position-1].value
            var diff: String = String (describing: delta)
            if (delta > 0) {
                diff = "+" + diff
            }
            difference.text = String (describing: diff)
        } else {
            difference.text = ""
        }
        current.text = sampleDate + "\n" + String (describing: chartManager.selectedSample.value) + " mg/DL " + self.chartManager.selectedSample.trend
    }
    
    public func onLoggedIn(event: Event){
        // get blood glucose levels from Dexcom
        dxBridge.getGlucoseValues()
    } 
    
    @objc func update() {
        dxBridge.getGlucoseValues()
    }
    
    @IBAction func fullTime(_ sender: Any) {
        chartManager.fulltimeView()
    }

    @IBAction func last3Hours(_ sender: Any) {
        chartManager.recentView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
