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
    
    private lazy var launchStoryboard = UIStoryboard(name: "LaunchScreen", bundle: nil)
    
    private lazy var launchController: UIViewController = {
        
        return self.launchStoryboard.instantiateViewControllerWithIdentifier( "launchVC" )
    }()

    private lazy var mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    private lazy var navController: UINavigationController = {
        return self.mainStoryboard.instantiateViewControllerWithIdentifier("rootNavigationController")
            as! UINavigationController
    }()
    
    private let storeName = "OpenLibraryBrowser"
    
    private let operationQueue = OperationQueue()
    private var reachabilityOperation: OLReachabilityOperation?
    private var generalSearchResultsCoordinator: GeneralSearchResultsCoordinator?

    private var coreDataStack: CoreDataStack?
    
    func nukeObsoleteStore() -> Void {
        
        if let currentVersion = NSBundle.getAppVersionString() {

            let storeFolder = NSFileManager().URLsForDirectory( .DocumentDirectory, inDomains: .UserDomainMask ).first!
            let versionURL = storeFolder.URLByAppendingPathComponent( storeName + ".version" )
            let previousVersion = NSKeyedUnarchiver.unarchiveObjectWithFile( versionURL.path! ) as? String
            
            if nil == previousVersion || currentVersion != previousVersion {
                
                let archiveURL = storeFolder.URLByAppendingPathComponent( storeName + ".sqlite" )
                
                do {
                    /*
                     If we already have a file at this location, just delete it.
                     Also, swallow the error, because we don't really care about it.
                     */
                    try NSFileManager.defaultManager().removeItemAtURL( archiveURL )

                    let searchStateURL = storeFolder.URLByAppendingPathComponent( "SearchState" )
                    try NSFileManager.defaultManager().removeItemAtURL( searchStateURL )
                }
                catch {}

                NSKeyedArchiver.archiveRootObject( currentVersion, toFile: versionURL.path! )
            }
        }
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        window = UIWindow( frame: UIScreen.mainScreen().bounds )
        window?.rootViewController = launchController

//        nukeObsoleteStore()

        CoreDataStack.constructSQLiteStack( withModelName: storeName ) {
            
            result in
            
            switch result {
                
            case .Success(let stack):
                
                self.coreDataStack = stack
                
                self.coreDataStack?.privateQueueContext.performBlockAndWait {
                    self.coreDataStack?.privateQueueContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                }
                self.coreDataStack?.mainQueueContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

                OLLanguage.retrieveLanguages( self.operationQueue, coreDataStack: stack )
                
                let delayTime = dispatch_time( DISPATCH_TIME_NOW, Int64( 0.5 * Double( NSEC_PER_SEC ) ) )
                
                dispatch_after( delayTime, dispatch_get_main_queue() ) {
                    
                    dispatch_async( dispatch_get_main_queue() ) {
                        
                        self.window?.rootViewController = self.navController                   }
                }

            case .Failure(let error):
                assertionFailure("\(error)")
                
            }
        }
        
        window?.makeKeyAndVisible()
                
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
    }

    func getGeneralSearchCoordinator( destVC: OLSearchResultsTableViewController ) -> GeneralSearchResultsCoordinator {
        
        guard let queryCoordinator = self.generalSearchResultsCoordinator else {
        
            generalSearchResultsCoordinator =
                GeneralSearchResultsCoordinator(
                        tableVC: destVC,
                        coreDataStack: coreDataStack!,
                        operationQueue: operationQueue
                    )
            
            return self.generalSearchResultsCoordinator!
        }
        
        return queryCoordinator
    }
    
}

