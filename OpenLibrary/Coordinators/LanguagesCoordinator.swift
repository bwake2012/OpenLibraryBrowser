//
//  LanguagesCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/17/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData

//import BNRCoreDataStack
import PSOperations

private let kLanguagesCache = "languagesCache"

class LanguagesCoordinator: OLQueryCoordinator, NSFetchedResultsControllerDelegate {
    
    fileprivate let kPageSize = 1000
    
    typealias FetchedOLLanguageController = NSFetchedResultsController< OLLanguage >
    
    var searchResults = SearchResults()
    
    var languagesGetOperation: PSOperation?

    fileprivate lazy var fetchedResultsController: FetchedOLLanguageController = {
        
        let fetchRequest = OLLanguage.buildFetchRequest()
        
        fetchRequest.sortDescriptors =
            [
                NSSortDescriptor(key: "index", ascending: true)
            ]
        fetchRequest.fetchBatchSize = 100
        
        let frc = FetchedOLLanguageController(
                        fetchRequest: fetchRequest,
                        managedObjectContext: self.dataStack.mainQueueContext,
                        sectionNameKeyPath: nil,
                        cacheName: nil ) // kLanguagesCache )
        
        frc.delegate = self
        return frc
    }()
    
    override init( operationQueue: PSOperationQueue, dataStack: OLDataStack, viewController: UIViewController ) {
        
        super.init( operationQueue: operationQueue, dataStack: dataStack, viewController: viewController )
        
        updateUI()
    }
    
    func newQuery( _ userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        self.searchResults = SearchResults()
        
        self.languagesGetOperation =
            LanguagesGetOperation(
                dataStack: dataStack
            ) {
                
                DispatchQueue.main.async {
                    
                    refreshControl?.endRefreshing()
                    self.languagesGetOperation = nil
                }
        }
        
        languagesGetOperation!.userInitiated = userInitiated
        operationQueue.addOperation( languagesGetOperation! )
        
    }
    
    // MARK: SearchResultsUpdater
    func updateResults(_ searchResults: SearchResults) -> Void {
        
        self.searchResults = searchResults
    }
    
    func updateUI() {
        
        do {
//            NSFetchedResultsController< OLLanguage >.deleteCache( withName: kLanguagesCache )
            try fetchedResultsController.performFetch()

            controllerDidPerformFetch( fetchedResultsController )
        }
        catch {
            print("Error in the fetched results controller: \(error).")
        }
    }
    
    // MARK: FetchedResultsControllerDelegate
    func controllerDidPerformFetch(_ controller: FetchedOLLanguageController) {
        
        if 0 == controller.sections?[0].numberOfObjects ?? 0 {
            
            newQuery( true, refreshControl: nil )
        }
    }
    
 }
