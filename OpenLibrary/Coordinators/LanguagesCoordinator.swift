//
//  LanguagesCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/17/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData

import BNRCoreDataStack
import PSOperations

private let kLanguagesCache = "languagesCache"

class LanguagesCoordinator: OLQueryCoordinator, FetchedResultsControllerDelegate {
    
    fileprivate let kPageSize = 1000
    
    typealias FetchedOLLanguageController = FetchedResultsController< OLLanguage >
    
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
                        managedObjectContext: self.coreDataStack.mainQueueContext,
                        sectionNameKeyPath: nil,
                        cacheName: nil ) // kLanguagesCache )
        
        frc.setDelegate( self )
        return frc
    }()
    
    override init( operationQueue: PSOperationQueue, coreDataStack: OLDataStack, viewController: UIViewController ) {
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: viewController )
        
        updateUI()
    }
    
    func newQuery( _ userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        self.searchResults = SearchResults()
        
        self.languagesGetOperation =
            LanguagesGetOperation(
                coreDataStack: coreDataStack
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
        }
        catch {
            print("Error in the fetched results controller: \(error).")
        }
    }
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch(_ controller: FetchedOLLanguageController) {
        
        if 0 == controller.count {
            
            newQuery( true, refreshControl: nil )
        }
    }
    
    func fetchedResultsControllerWillChangeContent( _ controller: FetchedOLLanguageController ) {
    }
    
    func fetchedResultsControllerDidChangeContent( _ controller: FetchedOLLanguageController ) {
    }
    
    func fetchedResultsController( _ controller: FetchedOLLanguageController,
                                   didChangeObject change: FetchedResultsObjectChange< OLLanguage > ) {
//        switch change {
//        case let .Insert(_, indexPath):
//            break
//            
//        case let .Delete(_, indexPath):
//            break
//            
//        case let .Move(_, fromIndexPath, toIndexPath):
//            break
//            
//        case let .Update(_, indexPath):
//            break
//        }
    }
    
    func fetchedResultsController(_ controller: FetchedOLLanguageController,
                                  didChangeSection change: FetchedResultsSectionChange< OLLanguage >) {
//        switch change {
//        case let .Insert(_, index):
//            break
//            
//        case let .Delete(_, index):
//            break
//        }
    }
 }
