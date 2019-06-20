//
//  AuthorEditionsCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/26/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import UIKit
import CoreData

//import BNRCoreDataStack
import PSOperations

private let kAuthorEditonsCache = "authorEditionsCache"
    
private let kPageSize = 100

class AuthorEditionsCoordinator: OLQueryCoordinator, NSFetchedResultsControllerDelegate {
    
    typealias FetchedAuthorEditionsController = NSFetchedResultsController< OLEditionDetail >
//    typealias FetchedAuthorEditionChange = NSFetchedResultsObjectChange< OLEditionDetail >
//    typealias FetchedAuthorEditionSectionChange = NSFetchedResultsSectionChange< OLEditionDetail >
    
    weak var tableVC: UITableViewController?
    
    var authorEditionsGetOperation: PSOperation?

    fileprivate lazy var fetchedResultsController: FetchedAuthorEditionsController = {
        
        let fetchRequest = OLEditionDetail.buildFetchRequest()

        let secondsPerDay = TimeInterval( 24 * 60 * 60 )
        let today = NSDate()
        let lastWeek = today.addingTimeInterval( -7 * secondsPerDay )
        
        fetchRequest.predicate = NSPredicate( format: "author_key==%@ && retrieval_date > %@", self.authorKey, lastWeek as NSDate )
        
        fetchRequest.sortDescriptors =
            [NSSortDescriptor(key: "coversFound", ascending: false),
             NSSortDescriptor(key: "index", ascending: true)]
        fetchRequest.fetchBatchSize = 100
        
        let frc = FetchedAuthorEditionsController( fetchRequest: fetchRequest,
            managedObjectContext: self.dataStack.mainQueueContext,
            sectionNameKeyPath: nil,
            cacheName: nil )
        
        frc.delegate = self
        return frc
    }()
    
    var authorKey = ""
    var worksCount = Int( kPageSize * 2 )
    var searchResults = SearchResults()
    
    var highWaterMark = 0
    
    init( authorKey: String, tableVC: UITableViewController, dataStack: OLDataStack, operationQueue: PSOperationQueue ) {
        
        self.authorKey = authorKey
        self.tableVC = tableVC
        
        super.init( operationQueue: operationQueue, dataStack: dataStack, viewController: tableVC )
        
        updateUI()
    }
    
    func numberOfSections() -> Int {
        
        return fetchedResultsController.sections?.count ?? 0
    }

    func numberOfRowsInSection( _ section: Int ) -> Int {

        return fetchedResultsController.sections?[section].objects?.count ?? 0
    }
    
    func objectAtIndexPath( _ indexPath: IndexPath ) -> OLEditionDetail? {
        
        if needAnotherPage( (indexPath as NSIndexPath).row, highWaterMark: highWaterMark ) {
            
            nextQueryPage( highWaterMark )
            
            highWaterMark += searchResults.pageSize
        }
        
        guard let sections = fetchedResultsController.sections else {
            assertionFailure("Sections missing")
            return nil
        }
        
        let section = sections[indexPath.section]
        guard let itemsInSection = section.objects as? [OLEditionDetail] else {
            fatalError("Missing items")
        }
        
        if indexPath.row >= itemsInSection.count {
            return nil
        } else {
            return itemsInSection[indexPath.row]
        }
    }
    
    func updateUI() {

        do {
//            NSFetchedResultsController< OLEditionDetail >.deleteCache( withName: kAuthorEditonsCache )
            try fetchedResultsController.performFetch()

            controllerDidPerformFetch( fetchedResultsController )
        }
        catch {
            print("Error in the fetched results controller: \(error).")
        }
        
        tableVC?.tableView.reloadData()
    }

    func newQuery( _ authorKey: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) {

        guard libraryIsReachable() else {
            
            updateHeader( "library is unreachable" )
            return
        }
        
        updateHeader( "" )
        if nil == authorEditionsGetOperation {
        
            self.searchResults = SearchResults()
            self.authorKey = authorKey
            self.highWaterMark = 0
            
            authorEditionsGetOperation =
                AuthorEditionsGetOperation(
                        queryText: authorKey,
                        offset: 0,
                        dataStack: dataStack,
                        updateResults: self.updateResults
                    ) {

                        DispatchQueue.main.async {
                            
                                refreshControl?.endRefreshing()
                                self.updateUI()
                            }
                    }
            
            authorEditionsGetOperation!.userInitiated = userInitiated
            operationQueue.addOperation( authorEditionsGetOperation! )
        }
    }
    
    func nextQueryPage( _ offset: Int ) -> Void {
        
        guard libraryIsReachable() else {
            
            updateHeader( "library is unreachable" )
            return
        }
        
        updateHeader( "" )
        if 0 == operationQueue.operationCount && !authorKey.isEmpty && highWaterMark < searchResults.numFound {
            
            authorEditionsGetOperation =
                AuthorEditionsGetOperation(
                        queryText: self.authorKey,
                        offset: offset,
                        dataStack: dataStack,
                        updateResults: self.updateResults
                    ) {
                
                DispatchQueue.main.async {
    //                refreshControl?.endRefreshing()
//                    self.updateUI()
                }
            }
            
            authorEditionsGetOperation!.userInitiated = false
            operationQueue.addOperation( authorEditionsGetOperation! )
        }
    }
    
    fileprivate func needAnotherPage( _ index: Int, highWaterMark: Int ) -> Bool {
        
        return
            !authorKey.isEmpty &&
            highWaterMark < worksCount &&
            index >= ( highWaterMark - ( searchResults.pageSize / 4 ) )
    }
    
    // MARK: SearchResultsUpdater
    func updateResults(_ searchResults: SearchResults) -> Void {
        
        self.searchResults = searchResults
        self.highWaterMark = searchResults.start + searchResults.pageSize

        DispatchQueue.main.async {
            [weak self] in
            
            if let strongSelf = self {
                
                strongSelf.updateFooter()
            }
        }
    }
    
    fileprivate func updateHeader( _ string: String = "" ) {
        
        updateTableHeader( tableVC?.tableView, text: string )
    }
    
    fileprivate func updateFooter( _ text: String = "" ) -> Void {
        
        updateTableFooter( tableVC?.tableView, highWaterMark: highWaterMark, numFound: searchResults.numFound, text: text )
    }
    
    // MARK: FetchedResultsControllerDelegate
    func controllerDidPerformFetch(_ controller: FetchedAuthorEditionsController) {
        
        let detail = objectAtIndexPath( IndexPath( row: 0, section: 0 ) )
        if nil == detail {
            
            newQuery( authorKey, userInitiated: true, refreshControl: nil )
            
        } else if let detail = detail {
            
            if detail.isProvisional {
                
                newQuery( authorKey, userInitiated: true, refreshControl: nil )

            } else {
                
                highWaterMark = numberOfRowsInSection( 0 )
            }
        }
    }
    
    func controllerDidChangeContent( _ controller: NSFetchedResultsController<NSFetchRequestResult> ) {
        
        if let tableView = tableVC?.tableView {
            
            // NSLog( "fetchedResultsControllerDidChangeContent start" )
            
            tableView.beginUpdates()
            
            tableView.deleteSections( deletedSectionIndexes as IndexSet, with: .automatic )
            tableView.insertSections( insertedSectionIndexes as IndexSet, with: .automatic )
            
            tableView.deleteRows( at: deletedRowIndexPaths as [IndexPath], with: .left )
            tableView.insertRows( at: insertedRowIndexPaths as [IndexPath], with: .right )
            tableView.reloadRows( at: updatedRowIndexPaths as [IndexPath], with: .automatic )
            
            tableView.endUpdates()
            
            // nil out the collections so they are ready for their next use.
            self.insertedSectionIndexes = NSMutableIndexSet()
            self.deletedSectionIndexes = NSMutableIndexSet()
            
            self.deletedRowIndexPaths = []
            self.insertedRowIndexPaths = []
            self.updatedRowIndexPaths = []
            
            // NSLog( "fetchedResultsControllerDidChangeContent end" )
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            if !insertedSectionIndexes.contains( newIndexPath!.section ) {
                insertedRowIndexPaths.append( newIndexPath! )
            }
            break
            
        case .delete:
            if !deletedSectionIndexes.contains( indexPath!.section ) {
                deletedRowIndexPaths.append( indexPath! )
            }
            break
            
        case .move:
            if !insertedSectionIndexes.contains( newIndexPath!.section ) {
                insertedRowIndexPaths.append( newIndexPath! )
            }
            if !deletedSectionIndexes.contains( indexPath!.section ) {
                deletedRowIndexPaths.append( indexPath! )
            }
            
        case .update:
            updatedRowIndexPaths.append( indexPath! )

        @unknown default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        switch type {
        case .insert:
            insertedSectionIndexes.add( sectionIndex )
        case .delete:
            deletedSectionIndexes.add( sectionIndex )
        default:
            break
        }
    }
}
