//
//  AuthorWorksCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/26/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import UIKit
import CoreData

import BNRCoreDataStack

private let kWorksByAuthorCache = "worksByAuthor"
    
class AuthorWorksCoordinator: NSObject, FetchedResultsControllerDelegate {
    
    typealias FetchedOLWorkDetailController = FetchedResultsController< OLWorkDetail >
    
    let tableView: UITableView?

    var operationQueue: OperationQueue
    
    let coreDataStack: CoreDataStack
    private lazy var fetchedResultsController: FetchedOLWorkDetailController = {
        
        let fetchRequest = NSFetchRequest( entityName: OLWorkDetail.entityName )
        fetchRequest.predicate = NSPredicate( format: "author_key==%@", "/authors/\(self.authorKey)" )
        
        fetchRequest.sortDescriptors =
            [NSSortDescriptor(key: "coversFound", ascending: false),
             NSSortDescriptor(key: "index", ascending: true)]
        
        let frc = FetchedOLWorkDetailController( fetchRequest: fetchRequest,
            managedObjectContext: self.coreDataStack.mainQueueContext,
            sectionNameKeyPath: nil )
        
        frc.setDelegate( self )
        return frc
    }()
    
    var authorKey = ""
    var worksCount = Int( 0 )
    var searchResults = SearchResults()
    
    var highWaterMark = 0
    
    init?( searchInfo: OLAuthorSearchResult.SearchInfo, tableView: UITableView, coreDataStack: CoreDataStack, operationQueue: OperationQueue ) {
        
        self.authorKey = searchInfo.key
        self.worksCount = searchInfo.work_count
        self.tableView = tableView
        self.operationQueue = operationQueue
        self.coreDataStack = coreDataStack
        
        super.init()
        
        updateUI()
    }
    
    func numberOfSections() -> Int {
        
        return fetchedResultsController.sections?.count ?? 0
    }

    func numberOfRowsInSection( section: Int ) -> Int {

        return max( self.worksCount, fetchedResultsController.sections?[section].objects.count ?? 0 )
    }
    
    
    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLWorkDetail? {
        
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
    
    func displayToCell( cell: AuthorWorksTableViewCell, indexPath: NSIndexPath ) -> OLWorkDetail? {
        
        if needAnotherPage( indexPath.row ) {
            
            nextQueryPage( highWaterMark )
        }
        
        guard let result = objectAtIndexPath( indexPath ) else { return nil }
        
        cell.configure( result )
        
        print( "work: \(result.title) has covers: \(!result.covers.isEmpty)" )
        
        let localURL = result.localURL( "S" )
        if !cell.displayImage( localURL ) {
            
            if !result.covers.isEmpty {
                
                let url = localURL
                let workCoverGetOperation =
                    ImageGetOperation( numberID: result.covers[0], imageKeyName: "id", localURL: url, size: "S", type: "b" )
                        {
                        
                        dispatch_async( dispatch_get_main_queue() ) {
                            
                            cell.displayImage( url )
                        }
                }
                
                workCoverGetOperation.userInitiated = true
                operationQueue.addOperation( workCoverGetOperation )
            }
        }
        
        return result
    }
    
    func updateUI() {

        do {
            NSFetchedResultsController.deleteCacheWithName( kWorksByAuthorCache )
            try fetchedResultsController.performFetch()
        }
        catch {
            print("Error in the fetched results controller: \(error).")
        }
    }

    func newQuery( authorKey: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) {

        self.searchResults = SearchResults()
        self.authorKey = authorKey
        self.highWaterMark = 0
//        self.tableView.scrollToRowAtIndexPath( NSIndexPath( forRow: 0, inSection: 0 ), atScrollPosition: .Top, animated: false )
        
        let authorWorksGetOperation =
            AuthorWorksGetOperation(
                    queryText: authorKey,
                    offset: 0,
                    coreDataStack: coreDataStack,
                    updateResults: self.updateResults
                ) {

                    dispatch_async( dispatch_get_main_queue() ) {
                        
                            refreshControl?.endRefreshing()
                            self.tableView?.reloadData()
                        }
                }
        
        authorWorksGetOperation.userInitiated = userInitiated
        operationQueue.addOperation( authorWorksGetOperation )
        
        print( "operationQueue:\(operationQueue.operationCount) \(operationQueue.suspended ? "Suspended" : "Active")" )
        for op in operationQueue.operations {
            
            print( "\(op.name) \(op.executing ? "executing" : (op.finished ? "finished" : (op.cancelled ? "cancelled" : (op.ready ? "ready" : "not ready"))))" )
        }
    }
    
    func nextQueryPage( offset: Int ) -> Void {
        
        if 0 == operationQueue.operationCount && !authorKey.isEmpty {
            
            let authorWorksGetOperation =
                AuthorWorksGetOperation(
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
            
            authorWorksGetOperation.userInitiated = false
            operationQueue.addOperation( authorWorksGetOperation )
        }
    }
    
    private func needAnotherPage( index: Int ) -> Bool {
        
        return
            operationQueue.operationCount == 0 &&
            !authorKey.isEmpty &&
            highWaterMark < self.worksCount &&
            index >= ( highWaterMark - ( searchResults.pageSize / 4 ) )
    }
    
    // MARK: SearchResultsUpdater
    func updateResults(searchResults: SearchResults) -> Void {
        
        self.searchResults = searchResults
        self.highWaterMark = searchResults.start + searchResults.pageSize
    }
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch( controller: FetchedOLWorkDetailController ) {
        
        if 0 == controller.count {
            
            newQuery( authorKey, userInitiated: true, refreshControl: nil )

        } else {
            
            highWaterMark = controller.count
        }
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedOLWorkDetailController ) {
//        tableView?.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedOLWorkDetailController ) {
//        tableView?.endUpdates()
    }
    
    func fetchedResultsController( controller: FetchedOLWorkDetailController,
        didChangeObject change: FetchedResultsObjectChange< OLWorkDetail > ) {
            switch change {
            case let .Insert(_, indexPath):
                // tableView?.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                break
                
            case let .Delete(_, indexPath):
                // tableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                break
                
            case let .Move(_, fromIndexPath, toIndexPath):
                tableView?.moveRowAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
                
            case let .Update(_, indexPath):
                tableView?.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
    }
    
    func fetchedResultsController(controller: FetchedOLWorkDetailController,
        didChangeSection change: FetchedResultsSectionChange< OLWorkDetail >) {
            switch change {
            case let .Insert(_, index):
                tableView?.insertSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
                
            case let .Delete(_, index):
                tableView?.deleteSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
            }
    }
}
