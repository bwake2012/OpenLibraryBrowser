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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: Properties
    var window: UIWindow?
    
    private let operationQueue = OperationQueue()

    private var coreDataStack: CoreDataStack? {
        
        didSet {
            
//            if nil != coreDataStack {
//                languagesCoordinator =
//                    LanguagesCoordinator( operationQueue: operationQueue, coreDataStack: coreDataStack! )
//            }
        
        }
    }
    private let launchStoryboard = UIStoryboard( name: "LaunchScreen", bundle: nil)
    private let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)

//    private lazy var loadingVC: UIViewController = {
//        return self.launchStoryboard.instantiateViewControllerWithIdentifier("launchVC")
//    }()
    private lazy var navController: UINavigationController = {
        return self.mainStoryboard.instantiateViewControllerWithIdentifier("rootNavigationController")
            as! UINavigationController
    }()
    
    private var languagesCoordinator: LanguagesCoordinator?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        // Override point for customization after application launch.
//        window = UIWindow(frame: UIScreen.mainScreen().bounds)
//        window?.rootViewController = loadingVC
        
        CoreDataStack.constructSQLiteStack(withModelName: "OpenLibraryBrowser") { result in
            switch result {
            case .Success(let stack):
                self.coreDataStack = stack
                
                dispatch_async( dispatch_get_main_queue() ) {

                    self.window?.rootViewController = self.navController
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

    func getAuthorSearchCoordinator( destVC: OLSearchResultsTableViewController ) -> AuthorSearchResultsCoordinator {

        return
            AuthorSearchResultsCoordinator(
                    tableVC: destVC,
                    coreDataStack: coreDataStack!,
                    operationQueue: operationQueue
                )
    }
    
    func getTitleSearchCoordinator( destVC: OLSearchResultsTableViewController ) -> TitleSearchResultsCoordinator {
        
        return
            TitleSearchResultsCoordinator(
                    tableVC: destVC,
                    coreDataStack: coreDataStack!,
                    operationQueue: operationQueue
                )
    }

}

