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

private let kAuthorEditonsCache = "authorEditionsCache"
    
private let kPageSize = 100

class AuthorEditionsCoordinator: OLQueryCoordinator, FetchedResultsControllerDelegate {
    
    typealias FetchedAuthorEditionsController = FetchedResultsController< OLEditionDetail >
    typealias FetchedAuthorEditionChange = FetchedResultsObjectChange< OLEditionDetail >
    typealias FetchedAuthorEditionSectionChange = FetchedResultsSectionChange< OLEditionDetail >
    
    let tableVC: UITableViewController

    private lazy var fetchedResultsController: FetchedAuthorEditionsController = {
        
        let fetchRequest = NSFetchRequest( entityName: OLEditionDetail.entityName )

        let secondsPerDay = NSTimeInterval( 24 * 60 * 60 )
        let today = NSDate()
        let yesterday = today.dateByAddingTimeInterval( -secondsPerDay )
        
        fetchRequest.predicate = NSPredicate( format: "author_key==%@ && retrieval_date > %@", "\(self.authorKey)", yesterday )
        
        fetchRequest.sortDescriptors =
            [NSSortDescriptor(key: "coversFound", ascending: false),
             NSSortDescriptor(key: "index", ascending: true)]
        
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
    
    init( authorKey: String, tableVC: UITableViewController, coreDataStack: CoreDataStack, operationQueue: OperationQueue ) {
        
        self.authorKey = authorKey
        self.tableVC = tableVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
        
        updateUI()
    }
    
    func numberOfSections() -> Int {
        
        return fetchedResultsController.sections?.count ?? 0
    }

    func numberOfRowsInSection( section: Int ) -> Int {

        return max( worksCount, fetchedResultsController.sections?[section].objects.count ?? 0 )
    }
    
    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLEditionDetail? {
        
        if needAnotherPage( indexPath.row, highWaterMark: highWaterMark ) {
            
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
            NSFetchedResultsController.deleteCacheWithName( kAuthorEditonsCache )
            try fetchedResultsController.performFetch()
        }
        catch {
            print("Error in the fetched results controller: \(error).")
        }
        
        tableVC.tableView.reloadData()
    }

    func newQuery( authorKey: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) {

        self.searchResults = SearchResults()
        self.authorKey = authorKey
        self.highWaterMark = 0
        
        let authorEditionsGetOperation =
            AuthorEditionsGetOperation(
                    queryText: authorKey,
                    offset: 0,
                    coreDataStack: coreDataStack,
                    updateResults: self.updateResults
                ) {

                    dispatch_async( dispatch_get_main_queue() ) {
                        
                            refreshControl?.endRefreshing()
                            self.updateUI()
                        }
                }
        
        authorEditionsGetOperation.userInitiated = userInitiated
        operationQueue.addOperation( authorEditionsGetOperation )
        
//        print( "operationQueue:\(operationQueue.operationCount) \(operationQueue.suspended ? "Suspended" : "Active")" )
//        for op in operationQueue.operations {
//            
//            print( "\(op.name) \(op.executing ? "executing" : (op.finished ? "finished" : (op.cancelled ? "cancelled" : (op.ready ? "ready" : "not ready"))))" )
//        }
    }
    
    func nextQueryPage( offset: Int ) -> Void {
        
        if 0 == operationQueue.operationCount && !authorKey.isEmpty {
            
            let authorEditionsGetOperation =
                AuthorEditionsGetOperation(
                        queryText: self.authorKey,
                        offset: offset,
                        coreDataStack: coreDataStack,
                        updateResults: self.updateResults
                    ) {
                
                dispatch_async( dispatch_get_main_queue() ) {
    //                refreshControl?.endRefreshing()
//                    self.updateUI()
                }
            }
            
            authorEditionsGetOperation.userInitiated = false
            operationQueue.addOperation( authorEditionsGetOperation )
        }
    }
    
    private func needAnotherPage( index: Int, highWaterMark: Int ) -> Bool {
        
        return
            !authorKey.isEmpty &&
            highWaterMark < worksCount &&
            index >= ( highWaterMark - ( searchResults.pageSize / 4 ) )
    }
    
    // MARK: SearchResultsUpdater
    func updateResults(searchResults: SearchResults) -> Void {
        
        self.searchResults = searchResults
        self.highWaterMark = searchResults.start + searchResults.pageSize
    }
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch(controller: FetchedAuthorEditionsController) {
        
        let detail = objectAtIndexPath( NSIndexPath( forRow: 0, inSection: 0 ) )
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
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedAuthorEditionsController ) {
//        tableView?.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedAuthorEditionsController ) {
//        tableView?.endUpdates()
    }
    
    func fetchedResultsController( controller: FetchedAuthorEditionsController,
        didChangeObject change: FetchedAuthorEditionChange ) {
            switch change {
            case let .Insert(_, indexPath):
                // tableView?.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                break
                
            case let .Delete(_, indexPath):
                // tableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                break
                
            case let .Move(_, fromIndexPath, toIndexPath):
                tableVC.tableView.moveRowAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
                
            case let .Update(_, indexPath):
                tableVC.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
    }
    
    func fetchedResultsController( controller: FetchedAuthorEditionsController,
        didChangeSection change: FetchedAuthorEditionSectionChange ) {
            switch change {
            case let .Insert(_, index):
                tableVC.tableView.insertSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
                
            case let .Delete(_, index):
                tableVC.tableView.deleteSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
            }
    }
}
