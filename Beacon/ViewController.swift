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
import Lottie
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet weak var current: UILabel!
    @IBOutlet weak var fulltime: UIButton!
    @IBOutlet weak var difference: UILabel!
    @IBOutlet weak var detailsL: UILabel!
    @IBOutlet weak var news: UILabel!
    @IBOutlet weak var recent: UIButton!
    @IBOutlet weak var myChart: LineChartView!
    
    public var quotes: [String] = ["Diabetics are naturally sweet.",
                                   "You are Type-One-Der-Ful.",
                                   "Watch out, I am a diabadass.",
                                    "Fall asleep and your pancreas is mine!",
                                    "Remember, someone is thinking about you today.",
                                    "I am not ill, my pancreas is just lazy."]
    
    public var hkManager: HKManager!
    public var dxBridge: DexcomBridge!
    private var chartManager: ChartManager!
    private var setupBg: Background!
    private var updateTimer: Timer?
    private var recoverTimer: Timer?
    private var firstTime:DarwinBoolean = true
    private var results: [BGSample]!
    private var bodyFont: UIFont!
    private var quoteFont: UIFont!
    private var quoteText: UILabel!
    private var animationView: LOTAnimationView!
    private var heartView: LOTAnimationView!
    private var managedObjectContext: NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize coredata
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        /*
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        self.view.addGestureRecognizer(swipeLeft)*/
        
        // disable dimming
        UIApplication.shared.isIdleTimerDisabled = true
        
        // reset UI
        myChart.noDataText = ""
        recent.alpha = 0
        fulltime.alpha = 0
        
        // setup background
        setupBg = Background (parent: self)
        
        quoteText = UILabel()
        quoteText.font = quoteFont
        quoteText.text = getRandomQuote()
        quoteText.center = CGPoint(x: self.view.frame.size.height/2, y: self.view.frame.size.width/2)
        self.view.addSubview(quoteText)
        
        // font setup
        let detailsFont = UIFont(name: ".SFUIText-Semibold", size :12)
        bodyFont = UIFont(name: ".SFUIText-Semibold", size :11)
        quoteFont = UIFont(name: ".SFUIText-Semibold", size :18)
        let headerFont = UIFont(name: ".SFUIText-Semibold", size :26)
        let newsFont = UIFont(name: ".SF-Pro-Display-Thin", size :18)
        
        detailsL.font = detailsFont
        current.font = headerFont
        difference.font = newsFont
        fulltime.titleLabel?.font = bodyFont
        recent.titleLabel?.font = bodyFont
        
        // centers launch quote label
        news.center = CGPoint(x: view.frame.width/2,y: view.frame.height/2);
        news.text = getRandomQuote()
        
        // charts UI
        chartManager = ChartManager(lineChart: myChart)
        let selectionHandler = EventHandler(function: onSelection)
        chartManager.addEventListener(type: EventType.selection, handler: selectionHandler)
        
        dxBridge = DexcomBridge.shared()
        let DXBloodSamples = EventHandler(function: self.onBloodSamples)
        let authLoginHandler = EventHandler (function: self.glucoseIOFailed)
        let glucoseIOHandler = EventHandler (function: self.glucoseIOFailed)
        let hkAuthorizedHandler = EventHandler (function: self.onHKAuthorization)
        let hkHeartRateHandler = EventHandler (function: self.onHKHeartRate)
    
        // Do any additional setup after loading the view, typically from a nib.
        // initialize the Dexcom bridge
        hkManager = HKManager()
        hkManager.getHealthKitPermission()
        hkManager.addEventListener(type: EventType.authorized, handler: hkAuthorizedHandler)
        hkManager.addEventListener(type: EventType.heartRate, handler: hkHeartRateHandler)
        
        // wait for Dexcom data
        dxBridge.addEventListener(type: .bloodSamples, handler: DXBloodSamples)
        dxBridge.addEventListener(type: .glucoseIOError, handler: glucoseIOHandler)
        
        let when = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.dxBridge.getGlucoseValues()
        }
    }
    
    public func onBloodSamples(event: Event){
        
        // reposition encouragement label
        news.center = CGPoint(x: view.frame.width/2,y: -173+view.frame.height/2);
        news.text = "Your heart rate has been steady for the past 48 hours, maybe time for a run?"
        
        (UIApplication.shared.delegate as! AppDelegate).deleteSamplesData()
        
        // reference the result (Array of BGSample)
        results = dxBridge.bloodSamples
        
        // initiate daily samples records
        let dailySample = DailySamples(context: managedObjectContext)
        dailySample.createdAt = Date() as NSDate
        dailySample.name = "24 hour samples"
        
        var samples: [Any] = []
        
        // fill the results
        for result in results {
            let bgSample = GlucoseSample(context: managedObjectContext)
            bgSample.time = Int32(result.time)
            bgSample.value = Int32(result.value)
            bgSample.trend = result.trend
            samples.append(bgSample)
        }
        
        let data = NSSet(array: samples)
        
        dailySample.samples = data
        
        // save in coredata
        do {
            try self.managedObjectContext.save()
            
        } catch { print ("error while saving data") }
        
        let samplesRequest: NSFetchRequest<NSFetchRequestResult> = DailySamples.fetchRequest()
        
        do{
            let samples: [DailySamples] = try managedObjectContext.fetch(samplesRequest) as! [DailySamples]
            let records = samples[0].samples
        } catch { print ("error loading data") }
        
        // update charts UI
        chartManager.setData(data: results)
        self.onSelection(event: nil)
        
        let (_, _, sampleDate) = Utils.getDate(unixdate: Int(results[0].time))
        current.text = sampleDate + "\n" + String (describing: results[0].value) + " mg/DL " + results[0].trend
        
        // details UI
        var infosLeft: String = ""
        
        let average: Double = round(Math.computeAverage(samples: results))
        let averageHrate: Double = ceil(Math.computeAverage(samples: hkManager.heartRates))
        let maxSD: Double = average / 3
        
        // display results
        infosLeft +=  "24-hour report"
        infosLeft +=  "\n\nA1C: " + String(round(Math.A1C(samples: results)))
        infosLeft +=  "\nHeart BPM: " + String(round(averageHrate))
        infosLeft +=  "\nStandard Deviation: " + String (round(Math.computeSD(samples: results))) + ", ideal below: " + String(maxSD.roundTo(places: 2))
        infosLeft += "\nAverage: " + String (average) + " mg/dL"
        infosLeft += "\nAcceleration: " + String (chartManager.curvature.roundTo(places: 2)) + ", ideal close to: 0"
        
        recent.alpha = 1
        fulltime.alpha = 1
        news.alpha = 1
        
        // calculate distribution
        let highs: [BGSample] = Math.computeHighBG(samples: results)
        let lows: [BGSample] = Math.computeLowBG(samples: results)
        let normal: [BGSample] = Math.computeNormalRangeBG(samples: results)
        
        let averageHigh: Double = ceil(Math.computeAverage(samples: highs))
        let averageNormal: Double = ceil(Math.computeAverage(samples: normal))
        let averageLow: Double = ceil(Math.computeAverage(samples: lows))
        
        infosLeft += "\nAvg/High: " + String(describing: averageHigh.roundTo(places: 2)) + " mg/dL \nAvg/Normal: " + String(describing: averageNormal.roundTo(places: 2)) + " mg/dL \nAvg/Low: " + String(describing: averageLow.roundTo(places: 2)) + " mg/dL"
        
        // percentages
        let highsPercentage : Double = Double (highs.count) / Double (results.count)
        let normalRangePercentage : Double = Double (normal.count) / Double (results.count)
        let lowsPercentage : Double = Double (lows.count) / Double(results.count)
        
        let highRatio: Double = (24.0 * highsPercentage).roundTo(places: 2)
        infosLeft += "\nHighs: " + String ( highsPercentage.roundTo(places: 2) * 100 ) + "%"
       // infosRight += " "+String(describing: highRatio) + " hours total"
        let normalRatio: Double = (24.0 * normalRangePercentage).roundTo(places: 2)
        infosLeft += "\nNormal: " + String ( normalRangePercentage.roundTo(places: 2) * 100 ) + "%"
        //infosRight += " "+String(describing: normalRatio) + " hours total"
        let lowRatio: Double = (24.0 * lowsPercentage).roundTo(places: 2)
        infosLeft += "\nLows: " + String ( lowsPercentage.roundTo(places: 2) * 100 ) + "%"
        //infosRight += " "+String(describing: lowRatio) + " hours total"
        
        detailsL.text = infosLeft
    }
    
    public func onSelection(event: Event?){
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
    
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.left:
                //left view controller
                self.performSegue(withIdentifier: "Details", sender: self)
            default:
                break
            }
        }
    }
    
    public func recover() {
        updateTimer?.invalidate()
        let when = DispatchTime.now() + 10
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.recoverUpdate()
        }
    }
    
    public func onHKHeartRate (event: Event){}
    
    public func glucoseIOFailed (event: Event){
        detailsL.text = "Couldn't load your latest glucose readings.\nRetrying in 10 seconds..."
        recover()
    }
    
    public func onHKAuthorization (event: Event){
        hkManager.getHeartRate()
    }
    
    public func getRandomQuote() -> String{
        let randomIndex = Int(arc4random_uniform(UInt32(quotes.count)))
        return quotes[randomIndex]
    }
    
    @objc func recoverUpdate() {
        //dxBridge.login()
    }
    
    @objc func update() {
        dxBridge.getGlucoseValues()
        hkManager.getHeartRate()
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
