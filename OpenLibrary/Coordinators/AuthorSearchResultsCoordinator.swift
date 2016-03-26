//
//  AuthorQueryResultsCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/26/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import UIKit
import CoreData

import BNRCoreDataStack

private let kAuthorSearchCache = "authorNameSearch"
    
class AuthorSearchResultsCoordinator: NSObject, FetchedResultsControllerDelegate {
    
    typealias FetchedOLAuthorSearchResultController = FetchedResultsController< OLAuthorSearchResult >
    
    let tableView: UITableView?

    var operationQueue: OperationQueue
    
    let coreDataStack: CoreDataStack
    private lazy var fetchedResultsController: FetchedOLAuthorSearchResultController = {
        
        let request = NSFetchRequest(entityName: OLAuthorSearchResult.entityName)
        
        request.sortDescriptors = [
            NSSortDescriptor( key: "sequence", ascending: true ),
            NSSortDescriptor( key: "index", ascending: true )
        ]
        
        // request.fetchLimit = 100
        
        let controller =
            FetchedOLAuthorSearchResultController(
                fetchRequest: request,
                managedObjectContext: self.coreDataStack.mainQueueContext,
                sectionNameKeyPath: nil,
                cacheName: kAuthorSearchCache
        )
        
        controller.setDelegate( self )
        return controller
    }()
    
    var authorName = ""
    var searchResults = SearchResults()
    
    var highWaterMark = 0
    
    lazy var hasPhotos: [Bool] = {

        return [Bool]( count: self.fetchedResultsController.count, repeatedValue: true )
    }()
    
    init?( tableView: UITableView, coreDataStack: CoreDataStack, operationQueue: OperationQueue ) {
        
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

        let rows = max( searchResults.numFound, fetchedResultsController.sections?[section].objects.count ?? 0 )

        return rows
    }
    
    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLAuthorSearchResult? {
        
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
    
    func displayToCell( cell: AuthorSearchResultTableViewCell, indexPath: NSIndexPath ) -> OLAuthorSearchResult? {
        
        if needAnotherPage( indexPath.row ) {
            
            nextQueryPage( highWaterMark )
        }
        
        guard let result = objectAtIndexPath( indexPath ) else { return nil }

        cell.configure( result )
        
        print( "author: \(result.name) has photo: \(hasPhotos[Int(result.index)])" )

        let localURL = result.localURL( "S" )
        if cell.displayImage( localURL ) {
            
            if !hasPhotos[Int(result.index)] {

                hasPhotos[Int(result.index)] = true
            }

        } else {
        
            if hasPhotos[Int(result.index)] {
            
                queueGetAuthorThumbByOLID( cell, result: result )
            }
        }
        
        return result
    }
    
    func updateUI() {

        do {
            NSFetchedResultsController.deleteCacheWithName( kAuthorSearchCache )
            try fetchedResultsController.performFetch()
        }
        catch {

            print("Error in the fetched results controller: \(error).")
        }
        
        tableView!.reloadData()
    }

    func newQuery( authorName: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        self.searchResults = SearchResults()
        self.authorName = authorName
        self.highWaterMark = 0
//        self.tableView.scrollToRowAtIndexPath( NSIndexPath( forRow: 0, inSection: 0 ), atScrollPosition: .Top, animated: false )
        
        let authorSearchOperation =
            AuthorNameSearchOperation(
                    queryText: authorName,
                    offset: 0,
                    coreDataStack: coreDataStack,
                    updateResults: self.updateResults
                ) {

                    dispatch_async( dispatch_get_main_queue() ) {
                        
                            refreshControl?.endRefreshing()
                            self.updateUI()
                        }
                }
        
        authorSearchOperation.userInitiated = userInitiated
        operationQueue.addOperation( authorSearchOperation )
        
//        print( "operationQueue:\(operationQueue.operationCount) \(operationQueue.suspended ? "Suspended" : "Active")" )
//        for op in operationQueue.operations {
//            
//            print( "\(op.name) \(op.executing ? "executing" : (op.finished ? "finished" : (op.cancelled ? "cancelled" : (op.ready ? "ready" : "not ready"))))" )
//        }
    }
    
    func nextQueryPage( offset: Int ) -> Void {
        
        if 0 == operationQueue.operationCount && !authorName.isEmpty {
            
            let authorSearchOperation =
                AuthorNameSearchOperation(
                        queryText: self.authorName,
                        offset: offset,
                        coreDataStack: coreDataStack,
                        updateResults: self.updateResults
                    ) {
                
                dispatch_async( dispatch_get_main_queue() ) {
    //                refreshControl?.endRefreshing()
//                    self.updateUI()
                }
            }
            
            authorSearchOperation.userInitiated = false
            operationQueue.addOperation( authorSearchOperation )
        }
    }
    
    private func needAnotherPage( index: Int ) -> Bool {
        
        return
            operationQueue.operationCount == 0 &&
            !authorName.isEmpty &&
            highWaterMark < searchResults.numFound &&
            index >= ( highWaterMark - ( searchResults.pageSize / 4 ) )
    }
    
    // MARK: SearchResultsUpdater
    func updateResults(searchResults: SearchResults) -> Void {
        
        self.searchResults = searchResults
        self.highWaterMark = searchResults.start + searchResults.pageSize
    }
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch(controller: FetchedResultsController< OLAuthorSearchResult >) {

        tableView?.reloadData()
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedResultsController< OLAuthorSearchResult > ) {
//        tableView?.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedResultsController< OLAuthorSearchResult > ) {
//        tableView?.endUpdates()
    }
    
    func fetchedResultsController( controller: FetchedResultsController< OLAuthorSearchResult >,
        didChangeObject change: FetchedResultsObjectChange< OLAuthorSearchResult > ) {
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
    
    func fetchedResultsController(controller: FetchedResultsController< OLAuthorSearchResult >,
        didChangeSection change: FetchedResultsSectionChange< OLAuthorSearchResult >) {
            switch change {
            case let .Insert(_, index):
                tableView?.insertSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
                
            case let .Delete(_, index):
                tableView?.deleteSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
            }
    }
    
    // MARK: Utility
    func queueGetAuthorThumbByDetail( cell: AuthorSearchResultTableViewCell, result: OLAuthorSearchResult ) {
        
        let authorDetailGetOperation =
            AuthorDetailWithThumbGetOperation(
                queryText: result.key, size: "S",
                coreDataStack: self.coreDataStack ) {
                    
                    dispatch_async( dispatch_get_main_queue() ) {
                        
                        let url = result.localURL( "S" )
                        self.hasPhotos[Int(result.index)] = cell.displayImage( url )
                    }
        }
    
        authorDetailGetOperation.userInitiated = true
        self.operationQueue.addOperation( authorDetailGetOperation )
    }
    
    func queueGetAuthorThumbByOLID( cell: AuthorSearchResultTableViewCell, result: OLAuthorSearchResult ) {
        
        let url = result.localURL( "S" )
        
        let authorThumbnailGetOperation =
            ImageGetOperation( stringID: result.key, imageKeyName: "olid", localURL: url, size: "S", type: "a" ) {
                
                dispatch_async( dispatch_get_main_queue() ) {
                    
                    if !cell.displayImage( url ) {
                        
                        self.queueGetAuthorThumbByDetail( cell, result: result )
                    }
                }
        }
        
        authorThumbnailGetOperation.userInitiated = true
        operationQueue.addOperation( authorThumbnailGetOperation )
    }
}
