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

private let kLanguagesCache = "languagesCache"

class LanguagesCoordinator: OLQueryCoordinator, FetchedResultsControllerDelegate {
    
    private let kPageSize = 1000
    
    typealias FetchedOLLanguageController = FetchedResultsController< OLLanguage >
    
    var searchResults = SearchResults()
    
    var languagesGetOperation: Operation?

    private lazy var fetchedResultsController: FetchedOLLanguageController = {
        
        let fetchRequest = NSFetchRequest( entityName: OLLanguage.entityName )
//        fetchRequest.predicate = NSPredicate( format: "author_key==%@", "\(key)" )
        
        fetchRequest.sortDescriptors =
            [
                NSSortDescriptor(key: "index", ascending: true)
            ]
        
        let frc = FetchedOLLanguageController(
                        fetchRequest: fetchRequest,
                        managedObjectContext: self.coreDataStack.mainQueueContext,
                        sectionNameKeyPath: nil,
                        cacheName: kLanguagesCache )
        
        frc.setDelegate( self )
        return frc
    }()
    
    override init( operationQueue: OperationQueue, coreDataStack: CoreDataStack ) {
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
        
        updateUI()
    }
    
    func newQuery( userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        self.searchResults = SearchResults()
        
        self.languagesGetOperation =
            LanguagesGetOperation(
                offset: 0, limit: kPageSize,
                coreDataStack: coreDataStack,
                updateResults: self.updateResults
            ) {
                
                dispatch_async( dispatch_get_main_queue() ) {
                    
                    refreshControl?.endRefreshing()
                    self.languagesGetOperation = nil
                }
        }
        
        languagesGetOperation!.userInitiated = userInitiated
        operationQueue.addOperation( languagesGetOperation! )
        
    }
    
    // MARK: SearchResultsUpdater
    func updateResults(searchResults: SearchResults) -> Void {
        
        self.searchResults = searchResults
    }
    
    func updateUI() {
        
        do {
            NSFetchedResultsController.deleteCacheWithName( kLanguagesCache )
            try fetchedResultsController.performFetch()
        }
        catch {
            print("Error in the fetched results controller: \(error).")
        }
    }
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch(controller: FetchedOLLanguageController) {
        
        if 0 == controller.count {
            
            newQuery( true, refreshControl: nil )
        }
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedOLLanguageController ) {
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedOLLanguageController ) {
    }
    
    func fetchedResultsController( controller: FetchedOLLanguageController,
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
    
    func fetchedResultsController(controller: FetchedOLLanguageController,
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