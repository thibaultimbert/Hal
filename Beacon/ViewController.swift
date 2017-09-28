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
import ReachabilitySwift

class ViewController: UIViewController
{
    
    @IBOutlet weak var current: UILabel!
    @IBOutlet weak var recent: UIButton!
    @IBOutlet weak var fulltime: UIButton!
    @IBOutlet weak var difference: UILabel!
    @IBOutlet weak var detailsL: UILabel!
    @IBOutlet weak var news: UILabel!
    @IBOutlet weak var myChart: LineChartView!
    
    public var quotes: [String] = ["Diabetics are naturally sweet.",
                                   "You are Type-One-Der-Ful.",
                                   "Watch out, I am a diabadass.",
                                    "Fall asleep and your pancreas is mine!",
                                    "Remember, someone is thinking about you today.",
                                    "I am not ill, my pancreas is just lazy."]
    
    public var hkBridge: HealthKitBridge!
    public var remoteBridge: DexcomBridge!
    private var chartManager: ChartManager!
    private var setupBg: Background!
    private var updateTimer: Timer?
    private var refreshTimer: Timer?
    private var recoverTimer: Timer?
    private var firstTime:DarwinBoolean = true
    private var results: [GlucoseSample]!
    private var bodyFont: UIFont!
    private var quoteFont: UIFont!
    private var quoteText: UILabel!
    private var animationView: LOTAnimationView!
    private var heartView: LOTAnimationView!
    private var managedObjectContext: NSManagedObjectContext!
  // private var dailySummaryView:DailySummary!
    private var keyChain: KeychainSwift!
    private var size: Float = 0
    private var generator: UIImpactFeedbackGenerator!
    private var gestureRecognizer: UIGestureRecognizer!
    private var reachability: Reachability!
    private var toggle: DarwinBoolean = false

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // load credentials
        keyChain = KeychainSwift.shared()
        
        // detect connection changes (wifi, cellular, no network)
        reachability = Reachability()!
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged),name: ReachabilityChangedNotification,object: reachability)
        do{
            try reachability.startNotifier()
        }catch {
            print("Could not start reachability notifier")
        }
        
        // handling background and foreground states
        //NotificationCenter.default.addObserver(self, selector: #selector(self.resume), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(self.pause), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        
        // initialize coredata
        managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
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
        chartManager = ChartManager(parent: self, lineChart: myChart)
        let selectionHandler = EventHandler(function: onSelection)
        chartManager.addEventListener(type: EventType.selection, handler: selectionHandler)
        
        // initialize the Dexcom bridge
        remoteBridge = DexcomBridge.shared()
        let glucoseValuesHandler = EventHandler(function: self.onGlucoseValues)
        let refreshedTokenHandler = EventHandler(function: self.onTokenRefreshed)
        let onLoggedInHandler = EventHandler (function: self.onLoggedIn)
        let glucoseIOHandler = EventHandler (function: self.glucoseIOFailed)
        let hkAuthorizedHandler = EventHandler (function: self.onHKAuthorization)
        let hkHeartRateHandler = EventHandler (function: self.onHKHeartRate)
        
        hkBridge = HealthKitBridge.shared()
        hkBridge.getHealthKitPermission()
        hkBridge.addEventListener(type: EventType.authorized, handler: hkAuthorizedHandler)
        hkBridge.addEventListener(type: EventType.heartRate, handler: hkHeartRateHandler)
        
        // wait for Dexcom data
        remoteBridge.addEventListener(type: .glucoseValues, handler: glucoseValuesHandler)
        remoteBridge.addEventListener(type: .refreshToken, handler: refreshedTokenHandler)
        remoteBridge.addEventListener(type: .glucoseIOError, handler: glucoseIOHandler)
        
        animationView = LOTAnimationView(name: "hamburger")
        animationView.contentMode = .scaleAspectFill
        animationView.frame = CGRect(x: -40, y: -20, width: 130, height: 130)
        animationView.isUserInteractionEnabled = true
        self.view.addSubview(animationView)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleMenu(recognizer:)))
        animationView.addGestureRecognizer(tapRecognizer)
        
        resume()
    }
    
    func toggleMenu(recognizer: UITapGestureRecognizer) {
        DispatchQueue.main.async(execute:
        {
            // Now the animation has finished and our image is displayed on screen
            self.performSegue(withIdentifier: "Settings", sender: self)
        })
    }
    
    @IBAction func unwindToMain(sender: UIStoryboardSegue) {}
    
    @objc private func reachabilityChanged(note: Notification)
    {
        let reachability = note.object as! Reachability
        if !reachability.isReachable {
            self.pause()
            //news.text = "Uh, oh. You seem to have lost network, waiting on network availability..."
            //current.text = "---\n---"
            //difference.text = ""
        } else {
            self.resume()
            //DispatchQueue.main.async(execute: news.text = "Your heart rate has been steady for the past 48 hours, maybe time for a run?")
        }
    }
    
    public func onGlucoseValues(event: Event)
    {
        // updates background based on current time
        setupBg.updateBackground()
        
        // reposition encouragement label
        news.center = CGPoint(x: view.frame.width/2,y: -173+view.frame.height/2);
        news.text = "Your heart rate has been steady for the past 48 hours, maybe time for a run?"
        
        // clean past data (debug)
        (UIApplication.shared.delegate as! AppDelegate).deleteSamplesData()
        
        // reference the result (Array of BGSample)
        results = remoteBridge.bloodSamples
        
        /*
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
        
        do {
            try self.managedObjectContext.save()
            
        } catch { print ("error while saving data") }
        
        let samplesRequest: NSFetchRequest<NSFetchRequestResult> = DailySamples.fetchRequest()
        
        do{
            let samples: [DailySamples] = try managedObjectContext.fetch(samplesRequest) as! [DailySamples]
            let records = samples[0].samples
        } catch { print ("error loading data") }*/
        
        let sampleDate:String = results[0].time
        current.text = sampleDate + "\n" + String (describing: results[0].value) + " mg/DL " + results[0].trend
        
        // details UI
        var infosLeft: String = ""
        
        let average: Double = round(Math.computeAverage(samples: results))
        let averageHrate: Double = ceil(Math.computeAverage(samples: hkBridge.heartRates))
        let maxSD: Double = average / 3
        
        // update charts UI
        chartManager.setData(data: results, average: average)
        self.onSelection(event: nil)
        
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
        let highs: [GlucoseSample] = Math.computeHighBG(samples: results)
        let lows: [GlucoseSample] = Math.computeLowBG(samples: results)
        let normal: [GlucoseSample] = Math.computeNormalRangeBG(samples: results)
        
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
    
    public func onSelection(event: Event?)
    {
        let sampleDate:String = chartManager.selectedSample.time
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
        
        if (self.chartManager.selectedSample.trend != "")
        {
            current.text = sampleDate + "\n" + String (describing: chartManager.selectedSample.value) + " mg/DL " + self.chartManager.selectedSample.trend
        } else
        {
            current.text = sampleDate + "\n" + String (describing: chartManager.selectedSample.value) + " mg/DL"
        }
    }
    
    public func pause()
    {
        print("DEBUG:: PAUSING")
        updateTimer?.invalidate()
        refreshTimer?.invalidate()
    }
    
    public func resume()
    {
        print("DEBUG:: RESUMING")
        updateTimer?.invalidate()
        refreshTimer?.invalidate()
        let when = DispatchTime.now() + 1
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.updateTimer = Timer.scheduledTimer(timeInterval: 180, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
            self.refreshTimer = Timer.scheduledTimer(timeInterval: 480, target: self, selector: #selector(self.refresh), userInfo: nil, repeats: true)
            self.updateTimer?.fire()
        }
    }
    
    public func onTokenRefreshed (event: Event)
    {
        resume()
    }
    
    public func onLoggedIn (event: Event)
    {
        resume()
    }
    
    public func glucoseIOFailed (event: Event)
    {
        pause()
    }
    
    public func onHKHeartRate (event: Event){}
    
    public func onHKAuthorization (event: Event)
    {
        hkBridge.getHeartRate()
    }
    
    public func getRandomQuote() -> String
    {
        let randomIndex = Int(arc4random_uniform(UInt32(quotes.count)))
        return quotes[randomIndex]
    }

    @objc func update()
    {
        print("DEBUG:: Pulling latest data")
        remoteBridge.getGlucoseValues()
        hkBridge.getHeartRate()
    }
    
    @objc func refresh()
    {
        print("DEBUG:: Pulling latest data")
        pause()
        remoteBridge.refreshToken()
        hkBridge.getHeartRate()
    }
    
    @IBAction func fullTime(_ sender: Any)
    {
        let button: UIButton = sender as! UIButton
        recent.alpha = 1.0
        button.alpha = 0.5
        chartManager.fulltimeView()
    }

    @IBAction func last3Hours(_ sender: Any)
    {
        let button: UIButton = sender as! UIButton
        fulltime.alpha = 1.0
        button.alpha = 0.5
        chartManager.recentView()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
