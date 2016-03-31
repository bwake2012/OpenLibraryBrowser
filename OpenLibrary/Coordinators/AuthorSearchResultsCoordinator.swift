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

private let kPageSize = 100
    
class AuthorSearchResultsCoordinator: NSObject, FetchedResultsControllerDelegate {
    
    typealias FetchedOLAuthorSearchResultController = FetchedResultsController< OLAuthorSearchResult >
    
    let tableView: UITableView?

    var operationQueue: OperationQueue
    var authorSearchOperation: Operation?
    
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
    var nextOffset = 0
    
    lazy var hasPhotos = [Bool]()
    
    init?( tableView: UITableView, coreDataStack: CoreDataStack, operationQueue: OperationQueue ) {
        
        self.tableView = tableView
        self.operationQueue = operationQueue
        self.coreDataStack = coreDataStack
        
        super.init()
        
        updateUI()
    }
    
    func numberOfSections() -> Int {
        
        return fetchedResultsController.sections?.count ?? 1
    }

    func numberOfRowsInSection( section: Int ) -> Int {

        let rows = fetchedResultsController.sections?[section].objects.count ?? 0

        return rows
    }
    
    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLAuthorSearchResult? {
        
        if 0 == searchResults.numFound { return nil }
        
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
        
        let localURL = result.localURL( "S" )
        let index = Int( result.index )

        self.coreDataStack.mainQueueContext.saveContext()
        
        if cell.displayImage( localURL ) {
            
            hasPhotos[index] = true

        } else {
        
            if let detail = getAuthorDetail( result ) {
                
                hasPhotos[index] = detail.hasPhotos
            }
            if hasPhotos[index] {
            
                queueGetAuthorThumbByOLID( cell, key: result.key, parentID: result.objectID, index: index, url: localURL )
            }
        }
        
        // not all the authors have photos under their OLID. Some only have them under a photo ID
        print( "\(result.index) author: \(result.name) has photo: \(hasPhotos[index])" )

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
        
        if self.searchResults.numFound > 0 {
            
            self.tableView!.scrollToRowAtIndexPath( NSIndexPath( forRow: 0, inSection: 0 ), atScrollPosition: .Top, animated: false )
        }
        
        if authorName != self.authorName && nil == authorSearchOperation {
            
            self.searchResults = SearchResults()
            self.authorName = authorName
            self.highWaterMark = 0
            self.nextOffset = kPageSize
            self.hasPhotos = [Bool]()
            
            authorSearchOperation =
                AuthorNameSearchOperation(
                        queryText: authorName,
                        offset: highWaterMark, limit: kPageSize,
                        coreDataStack: coreDataStack,
                        updateResults: self.updateResults
                    ) {
                        [weak self] in

                        if let strongSelf = self {
                            
                            dispatch_async( dispatch_get_main_queue() ) {
                                
                                    refreshControl?.endRefreshing()
                                    strongSelf.updateUI()
                                }
                            strongSelf.authorSearchOperation = nil
                        }
                    }
            
            authorSearchOperation!.userInitiated = userInitiated
            operationQueue.addOperation( authorSearchOperation! )
        }
    }
    
    func nextQueryPage( offset: Int ) -> Void {
        
        if !authorName.isEmpty && nil == self.authorSearchOperation {
            
            nextOffset = offset + kPageSize
            authorSearchOperation =
                AuthorNameSearchOperation(
                        queryText: self.authorName,
                        offset: offset, limit: kPageSize,
                        coreDataStack: coreDataStack,
                        updateResults: self.updateResults
                    ) {
                
                    [weak self] in
                    dispatch_async( dispatch_get_main_queue() ) {
        //                refreshControl?.endRefreshing()
    //                    self.updateUI()
                    }
                    if let strongSelf = self {
                        
                        strongSelf.authorSearchOperation = nil
                    }
            }
            
            authorSearchOperation!.userInitiated = false
            operationQueue.addOperation( authorSearchOperation! )
        }
    }
    
    func clearQuery() {
        
        let queryClearOperation = AuthorSearchResultsDeleteOperation( coreDataStack: coreDataStack )
        
        queryClearOperation.userInitiated = false
        operationQueue.addOperation( queryClearOperation )
            
    }
    
    private func needAnotherPage( index: Int ) -> Bool {
        
        return
            nil == self.authorSearchOperation &&
            !authorName.isEmpty &&
            highWaterMark < searchResults.numFound &&
            index >= ( self.fetchedResultsController.count - 1 )
    }
    
    // MARK: SearchResultsUpdater
    func updateResults(searchResults: SearchResults) -> Void {
        
        self.searchResults = searchResults
        self.highWaterMark = searchResults.start + searchResults.pageSize
        if searchResults.numFound > hasPhotos.count {
            self.hasPhotos.appendContentsOf( [Bool]( count: searchResults.numFound - hasPhotos.count, repeatedValue: true ) )
        }
    }
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch(controller: FetchedResultsController< OLAuthorSearchResult >) {

        if authorName.isEmpty {
            self.highWaterMark = fetchedResultsController.count
            self.searchResults = SearchResults( start: 0, numFound: highWaterMark, pageSize: 100 )
            tableView?.reloadData()
            self.hasPhotos = [Bool]( count: highWaterMark, repeatedValue: true )
        }
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedResultsController< OLAuthorSearchResult > ) {
        tableView?.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedResultsController< OLAuthorSearchResult > ) {
        tableView?.endUpdates()
    }
    
    func fetchedResultsController( controller: FetchedResultsController< OLAuthorSearchResult >,
        didChangeObject change: FetchedResultsObjectChange< OLAuthorSearchResult > ) {
            switch change {
            case let .Insert(_, indexPath):
                tableView?.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                break
                
            case let .Delete(_, indexPath):
                tableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
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
    func queueGetAuthorThumbByDetail( cell: AuthorSearchResultTableViewCell, key: String, parentID: NSManagedObjectID, index: Int, url: NSURL ) {
        
        let authorDetailGetOperation =
            AuthorDetailWithThumbGetOperation(
            queryText: key, parentObjectID: parentID, size: "S",
                coreDataStack: self.coreDataStack ) {
                    [weak self] in
                    
                    guard let strongSelf = self else { return }
                    
                    if index < strongSelf.hasPhotos.count {
                        dispatch_async( dispatch_get_main_queue() ) {
                            
                            strongSelf.hasPhotos[Int(index)] = cell.displayImage( url )
                        }
                    }
        }
    
        authorDetailGetOperation.userInitiated = true
        self.operationQueue.addOperation( authorDetailGetOperation )
    }
    
    func queueGetAuthorThumbByOLID( cell: AuthorSearchResultTableViewCell, key: String, parentID: NSManagedObjectID, index: Int, url: NSURL ) {
        
        var olid = key
        if key.hasPrefix( kAuthorsPrefix ) {
            
            olid = key.substringFromIndex( key.startIndex.advancedBy( 9 ) )
        }
        
        let authorThumbnailGetOperation =
            ImageGetOperation( stringID: olid, imageKeyName: "olid", localURL: url, size: "S", type: "a" ) {
                
                dispatch_async( dispatch_get_main_queue() ) {
                    
                    if !cell.displayImage( url ) {
                        
                        self.queueGetAuthorThumbByDetail( cell, key: key, parentID: parentID, index: index, url: url )
                    }
                }
        }
        
        authorThumbnailGetOperation.userInitiated = true
        operationQueue.addOperation( authorThumbnailGetOperation )
    }
    
    func getAuthorDetail( result: OLAuthorSearchResult ) -> OLAuthorDetail? {
        
//        print( "\(result.name) toDetail: \(result.toDetail?.key)" )
        
        return result.toDetail
    }
}
