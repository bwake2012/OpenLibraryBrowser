//
//  AppDelegate.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit
import CoreData

import BNRCoreDataStack
import PSOperations

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: Properties
    var window: UIWindow?
    
    fileprivate lazy var launchStoryboard = UIStoryboard(name: "LaunchScreen", bundle: nil)
    
    fileprivate lazy var launchController: UIViewController = {
        
        return self.launchStoryboard.instantiateViewController( withIdentifier: "launchVC" )
    }()

    fileprivate lazy var mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    fileprivate lazy var navController: UINavigationController = {
        return self.mainStoryboard.instantiateViewController(withIdentifier: "rootNavigationController")
            as! UINavigationController
    }()
    
    fileprivate let operationQueue = PSOperationQueue()
    fileprivate var dataStack: OLDataStack?
    fileprivate var reachabilityOperation: OLReachabilityOperation?
    fileprivate var generalSearchResultsCoordinator: GeneralSearchResultsCoordinator?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow( frame: UIScreen.main.bounds )
        window?.rootViewController = launchController

        nukeObsoleteStore()
        
        let launchUserInterface = {

            OLLanguage.retrieveLanguages( self.operationQueue, coreDataStack: self.dataStack! )
            
            let delay = DispatchTime.now() + .milliseconds( 500 )
            DispatchQueue.main.asyncAfter( deadline: delay ) {
                
                let navController = self.navController
                navController.navigationBar.barStyle = .black
                self.window?.rootViewController = navController
            }
        }
        
        if #available(iOS 10.0, *) {
            
            print( "iOS 10 Core Data Stack" )
            self.dataStack =
                IOS10DataStack( operationQueue: operationQueue, completion: launchUserInterface )

        } else {
            
            print( "Big Nerd Ranch Core Data Stack" )
            self.dataStack =
                IOS09DataStack( operationQueue: operationQueue, completion: launchUserInterface )
        }

        window?.makeKeyAndVisible()
                
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        self.dataStack?.save()
    }

    func getGeneralSearchCoordinator( _ destVC: OLSearchResultsTableViewController ) -> GeneralSearchResultsCoordinator {
        
        guard let queryCoordinator = self.generalSearchResultsCoordinator else {
        
            generalSearchResultsCoordinator =
                GeneralSearchResultsCoordinator(
                        tableVC: destVC,
                        coreDataStack: dataStack!,
                        operationQueue: operationQueue
                    )
            
            return self.generalSearchResultsCoordinator!
        }
        
        return queryCoordinator
    }
    
}

