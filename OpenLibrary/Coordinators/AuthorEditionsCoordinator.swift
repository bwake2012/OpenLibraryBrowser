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

import BNRCoreDataStack
import PSOperations

private let kAuthorEditonsCache = "authorEditionsCache"
    
private let kPageSize = 100

class AuthorEditionsCoordinator: OLQueryCoordinator, FetchedResultsControllerDelegate {
    
    typealias FetchedAuthorEditionsController = FetchedResultsController< OLEditionDetail >
    typealias FetchedAuthorEditionChange = FetchedResultsObjectChange< OLEditionDetail >
    typealias FetchedAuthorEditionSectionChange = FetchedResultsSectionChange< OLEditionDetail >
    
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
            managedObjectContext: self.coreDataStack.mainQueueContext,
            sectionNameKeyPath: nil )
        
        frc.setDelegate( self )
        return frc
    }()
    
    var authorKey = ""
    var worksCount = Int( kPageSize * 2 )
    var searchResults = SearchResults()
    
    var highWaterMark = 0
    
    init( authorKey: String, tableVC: UITableViewController, coreDataStack: OLDataStack, operationQueue: PSOperationQueue ) {
        
        self.authorKey = authorKey
        self.tableVC = tableVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: tableVC )
        
        updateUI()
    }
    
    func numberOfSections() -> Int {
        
        return fetchedResultsController.sections?.count ?? 0
    }

    func numberOfRowsInSection( _ section: Int ) -> Int {

        return max( worksCount, fetchedResultsController.sections?[section].objects.count ?? 0 )
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
        if indexPath.row >= section.objects.count {
            return nil
        } else {
            return section.objects[indexPath.row]
        }
    }
    
    func updateUI() {

        do {
//            NSFetchedResultsController< OLEditionDetail >.deleteCache( withName: kAuthorEditonsCache )
            try fetchedResultsController.performFetch()
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
                        coreDataStack: coreDataStack,
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
                        coreDataStack: coreDataStack,
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
    func fetchedResultsControllerDidPerformFetch(_ controller: FetchedAuthorEditionsController) {
        
        let detail = objectAtIndexPath( IndexPath( row: 0, section: 0 ) )
        if nil == detail {
            
            newQuery( authorKey, userInitiated: true, refreshControl: nil )
            
        } else if let detail = detail {
            
            if detail.isProvisional {
                
                newQuery( authorKey, userInitiated: true, refreshControl: nil )

            } else {
                
                highWaterMark = controller.count
            }
        }
    }
    
    func fetchedResultsControllerWillChangeContent( _ controller: FetchedAuthorEditionsController ) {
//        tableView?.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( _ controller: FetchedAuthorEditionsController ) {
//        tableView?.endUpdates()
    }
    
    func fetchedResultsController( _ controller: FetchedAuthorEditionsController,
        didChangeObject change: FetchedAuthorEditionChange ) {
            switch change {
            case .insert(_, _):
                // tableView?.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                break
                
            case .delete(_, _):
                // tableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                break
                
            case let .move(_, fromIndexPath, toIndexPath):
                tableVC?.tableView.moveRow(at: fromIndexPath, to: toIndexPath)
                
            case let .update(_, indexPath):
                tableVC?.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
    }
    
    func fetchedResultsController( _ controller: FetchedAuthorEditionsController,
        didChangeSection change: FetchedAuthorEditionSectionChange ) {
            switch change {
            case let .insert(_, index):
                tableVC?.tableView.insertSections(IndexSet( integer: index ), with: .automatic)
                
            case let .delete(_, index):
                tableVC?.tableView.deleteSections(IndexSet( integer: index ), with: .automatic)
            }
    }
}
