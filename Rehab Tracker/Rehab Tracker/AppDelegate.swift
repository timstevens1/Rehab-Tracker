//
//  AppDelegate.swift
//  Rehab Tracker
//
//  Created by Sean Kates on 11/1/16.
//  Copyright © 2017 University of Vermont. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

// Check this page to see descriptions of UIApplicationDelegate https://developer.apple.com/documentation/uikit/uiapplicationdelegate?hl=et
/// This class handles some events that change the model of the app instead of just one view. It responses to important events in the lifetime of your app like logging in and basic settings.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // Initialize the pusher instance with key from server
    //let pusher = Pusher(key: "1a12b25128b9b2b28ee1")
    
    /// The backdrop for your app’s user interface and the object that dispatches events to your views
    var window: UIWindow?

    /// Tell the delegate that the launch process is almost done and the app is almost ready to run and finish all initialization. This method is called after state restoration has occurred but before the app’s window and other UI have been presented.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Define all the color schemes here for consistency
        // RED = 28, GREEN = 117, BLUE = 127
        // HEX = 1C757F
        // Navigation Bar Color Scheme
        UINavigationBar.appearance().barTintColor = UIColor.white
        UINavigationBar.appearance().tintColor = UIColor(red: 0.1098, green: 0.4588, blue: 0.498, alpha: 1.0)
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName:UIColor(red: 0.1098, green: 0.4588, blue: 0.498, alpha: 1.0)]
        
        // Tab Bar Color Scheme
        UITabBar.appearance().barTintColor = UIColor.white
        UITabBar.appearance().tintColor = UIColor(red: 0.1098, green: 0.4588, blue: 0.498, alpha: 1.0)
        
        // Button Color Scheme
        UIButton.appearance().setTitleColor(UIColor(red: 0.1098, green: 0.4588, blue: 0.498, alpha: 1.0), for: .normal)

        // Splash Screen Animation
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.backgroundColor = UIColor(red: 0.1098, green: 0.4588, blue: 0.498, alpha: 1.0)
        self.window!.makeKeyAndVisible()
        
        // rootViewController from StoryBoard
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        var navigationController : UIViewController
        if Util.returnCurrentUsersID() == Util.getDatabaseUsername() {
            Util.pushRegistration()
            navigationController = storyboard.instantiateViewController( withIdentifier:"Sync")
        }
        else{
            navigationController = storyboard.instantiateViewController( withIdentifier: "homeNavigation" )
        }
        self.window!.rootViewController = navigationController
        
        // logo mask
        navigationController.view.layer.mask = CALayer()
        navigationController.view.layer.mask?.contents = UIImage(named: "Splash-Logo.png")!.cgImage
        navigationController.view.layer.mask?.bounds = CGRect(x: 0, y: 0, width: 60, height: 60)
        navigationController.view.layer.mask?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        navigationController.view.layer.mask?.position = CGPoint(x: navigationController.view.frame.width / 2, y: navigationController.view.frame.height / 2)
        
        // logo mask background view
        let maskBgView = UIView(frame: navigationController.view.frame)
        maskBgView.backgroundColor = UIColor.white
        navigationController.view.addSubview(maskBgView)
        navigationController.view.bringSubview(toFront: maskBgView)
        
        // logo mask animation
        let transformAnimation = CAKeyframeAnimation(keyPath: "bounds")
        transformAnimation.duration = 1
        transformAnimation.beginTime = CACurrentMediaTime() + 1 //add delay of 1 second
        let initalBounds = NSValue(cgRect: (navigationController.view.layer.mask?.bounds)!)
        let secondBounds = NSValue(cgRect: CGRect(x: 0, y: 0, width: 50, height: 50))
        let finalBounds = NSValue(cgRect: CGRect(x: 0, y: 0, width: 2000, height: 2000))
        transformAnimation.values = [initalBounds, secondBounds, finalBounds]
        transformAnimation.keyTimes = [0, 0.5, 1]
        transformAnimation.timingFunctions = [CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut), CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)]
        transformAnimation.isRemovedOnCompletion = false
        transformAnimation.fillMode = kCAFillModeForwards
        navigationController.view.layer.mask?.add(transformAnimation, forKey: "maskAnimation")
        
        // logo mask background view animation
        UIView.animate(withDuration: 0.1,
                       delay: 1.5,
                       options: UIViewAnimationOptions.curveEaseIn,
                       animations: {
                        maskBgView.alpha = 0.0
        },
                       completion: { finished in
                        maskBgView.removeFromSuperview()
                        self.animationDidStop( finished: true )
        })
        
        // root view animation
        UIView.animate(withDuration: 0.25,
                       delay: 1.3,
                       options: [],
                       animations: {
                        self.window!.rootViewController!.view.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        },
                       completion: { finished in
                        UIView.animate(withDuration: 0.3,
                                       delay: 0.0,
                                       options: UIViewAnimationOptions.curveEaseInOut,
                                       animations: {
                                        self.window!.rootViewController!.view.transform = CGAffineTransform.identity
                        },
                                       completion: nil
                        )
        })
        registerForPushNotifications()

        return true
    }
    
    /// Remove mask when animation completes
    /// - Precondition: The logo animation has finished.
    /// - Postcondition: The mask is removed.
    func animationDidStop( finished flag: Bool ) {
        self.window!.rootViewController!.view.layer.mask = nil
    }

    /// Tell the delegate that the app is about to become inactive (called when leaving the foreground state)
    /// - Postcondition: Unsaved data are saved to ensure that it is not lost.
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        self.saveContext()
    }

    /// Tell the delegate that the app is now in the background
    /// - Postcondition: Unsaved data are saved to ensure that it is not lost.
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        self.saveContext()
    }

    /// Tell the delegate that the app is about to enter the foreground (called when transitioning out of the background state)
    func applicationWillEnterForeground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0

        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    /// Tell the delegate that the app has become active
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    /// Tell the delegate when the app is about to terminate (called only when the app is running. This method is not called if the app is suspended)
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack
    /// Create a container that encapsulates the Core Data stack in the application
    /// - Returns: A container for core data
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Rehab_Tracker")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support
    /// Save context to core data
    /// - Precondition: The state transits to the background or to the inactive state.
    /// - Postcondition: The context has been saved to core data.
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
    /// Obtain the authorization to show push notification
    /// - Postcondition: The system provides a device token of the phone where the app is installed on.
    func registerForPushNotifications() {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
                (granted, error) in
                print("Permission granted: \(granted)")
                guard granted else { return }
                self.getNotificationSettings()
        }
    }
    /// Retrieve the notification settings that the user allows
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async(execute: {
                UIApplication.shared.registerForRemoteNotifications()
            })
        }
    }
    
    /// Tell the delegate that the app successfully registered with Apple Push Notification service (APNs)
    /// - Precondition: The app has registered with the APN. `registerForRemoteNotifications` has been called.
    /// - Postcondition: The app has got the UDID and finished the push notification registration.
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        print(token)
        Util.setUDID(udid :token)
        if Util.returnCurrentUsersID() == Util.getDatabaseUsername(){
            print(Util.pushRegistration())
        }
        
    }
    
    /// Sent to the delegate when Apple Push Notification service cannot successfully complete the registration process
    /// - Precondition: The app has registered with the APN. `registerForRemoteNotifications` has been called.
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
}

