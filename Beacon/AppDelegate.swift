//
//  AppDelegate.swift
//  HAL
//
//  Created by Thibault Imbert on 7/12/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications
import CoreData
import Fabric
import Crashlytics
import OAuthSwift
//import DLLocalNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private var dxBridge: DexcomBridge = DexcomBridge.shared()
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        let onTokenReceivedHandler = EventHandler(function: self.onTokenReceived)
        dxBridge.addEventListener(type: EventType.token, handler: onTokenReceivedHandler)
        return UIInterfaceOrientationMask(rawValue: UIInterfaceOrientationMask.portrait.rawValue)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if (url.host == "oauth-swift") {
            OAuthSwift.handle(url: url)
        }
        let url:URL = url.absoluteURL
        let parameters: Dictionary = Utils.decomposeURL(url: url)
        let code: String = parameters["code"]!
        dxBridge.getToken(code: code)
        return true
    }
    
    public func onTokenReceived(event: Event)
    {
        if let vc = window?.rootViewController as? LoginViewController {
            print ("perform segue")
            vc.performSegue(withIdentifier: "Main", sender: vc)
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        Fabric.with([Crashlytics.self])
        UIApplication.shared.statusBarStyle = .lightContent
        
        // load the login view controller
        let mainStoryboardIpad : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let initialViewControlleripad : UIViewController = mainStoryboardIpad.instantiateViewController(withIdentifier: "Login") as UIViewController
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = initialViewControlleripad
        self.window?.makeKeyAndVisible()
        
        // Override point for customization after application launch.
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in }
            application.registerForRemoteNotifications()
         }
        
        var date = DateComponents()
        date.hour = 17
        date.minute = 44
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        
        let content = UNMutableNotificationContent()
        content.title = "title"
        content.body = "body"
        // make sure you give each request a unique identifier. (nextTriggerDate description)
        let request = UNNotificationRequest(identifier: String(Date().timeIntervalSince1970), content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print(error)
                return
            }
            print("scheduled")
        }
        
        // background fetch
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let vc = window?.rootViewController as? ViewController {
            vc.remoteBridge.getGlucoseValues(token: RemoteBridge.TOKEN, completionHandler: completionHandler)
            vc.hkBridge.getHeartRate()
        }
    }
    
    // Called when APNs has assigned the device a unique token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert token to string
        _ = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        // Print it to console
        //print("APNs device token: \(deviceTokenString)")
        // Persist it in your backend in case it's new
    }
    
    // Called when APNs failed to register the device for push notifications
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Print the error to console (you should alert the user that registration failed)
        print("APNs registration failed: \(error)")
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    // Push notification received
    func application(_ application: UIApplication, didReceiveRemoteNotification data: [AnyHashable : Any]) {
        // Print notification payload data
        print("Push notification received: \(data)")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Beacon")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Core Data Blog Glucose Samples Deletion support
    
    func deleteSamplesData () {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = DailySamples.fetchRequest()
        do {
            let samples: [DailySamples] = try context.fetch(fetchRequest) as! [DailySamples]
            for sample in samples {
                context.delete(sample)
                try context.save()
            }
        } catch {}
    }
}

