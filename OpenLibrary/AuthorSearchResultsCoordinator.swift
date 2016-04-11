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

class AuthorSearchResultsCoordinator: OLQueryCoordinator, FetchedResultsControllerDelegate {
    
    typealias FetchedOLAuthorSearchResultController = FetchedResultsController< OLAuthorSearchResult >
    
    let tableVC: UITableViewController
    
    var authorSearchOperation: Operation?
    
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
    
    init( tableVC: UITableViewController, coreDataStack: CoreDataStack, operationQueue: OperationQueue ) {
        
        self.tableVC = tableVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
        
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
        self.coreDataStack.mainQueueContext.saveContext()
        
        let havePhoto = result.displayThumbnail( cell.cellImage )
        
        switch havePhoto {
            
        case .unknown:
            assert( .unknown != havePhoto )
            
        case .olid:
            queueGetAuthorThumbByOLID( indexPath, key: result.key, url: localURL )
            
        case .id:
            if let detail = result.toDetail {
                queueGetAuthorThumbByID( indexPath, id: detail.firstImageID, url: localURL )
            }
            
        case .authorDetail:
            queueGetAuthorThumbByDetail( indexPath, key: result.key, parentID: result.objectID, url: localURL )
            
        case .local, .none:
            break
        }
        
        // not all the authors have photos under their OLID. Some only have them under a photo ID
        print( "\(result.index) author: \(result.name) has photo: \(havePhoto)" )
        
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
        
        tableVC.tableView.reloadData()
    }
    
    func newQuery( authorName: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        if self.searchResults.numFound > 0 {
            
            tableVC.tableView.scrollToRowAtIndexPath( NSIndexPath( forRow: 0, inSection: 0 ), atScrollPosition: .Top, animated: false )
        }
        
        if authorName != self.authorName && nil == authorSearchOperation {
            
            self.searchResults = SearchResults()
            self.authorName = authorName
            self.highWaterMark = 0
            self.nextOffset = kPageSize
            
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
                        //                        refreshControl?.endRefreshing()
                        //                        self.updateUI()
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
    }
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch(controller: FetchedResultsController< OLAuthorSearchResult >) {
        
        if authorName.isEmpty {
            self.highWaterMark = fetchedResultsController.count
            self.searchResults = SearchResults( start: 0, numFound: highWaterMark, pageSize: 100 )
            tableVC.tableView.reloadData()
        }
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedResultsController< OLAuthorSearchResult > ) {
        tableVC.tableView.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedResultsController< OLAuthorSearchResult > ) {
        tableVC.tableView.endUpdates()
    }
    
    func fetchedResultsController( controller: FetchedResultsController< OLAuthorSearchResult >,
                                   didChangeObject change: FetchedResultsObjectChange< OLAuthorSearchResult > ) {
        switch change {
        case let .Insert(_, indexPath):
            tableVC.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            break
            
        case let .Delete(_, indexPath):
            tableVC.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            break
            
        case let .Move(_, fromIndexPath, toIndexPath):
            tableVC.tableView.moveRowAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
            
        case let .Update(_, indexPath):
            tableVC.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    func fetchedResultsController(controller: FetchedResultsController< OLAuthorSearchResult >,
                                  didChangeSection change: FetchedResultsSectionChange< OLAuthorSearchResult >) {
        switch change {
        case let .Insert(_, index):
            tableVC.tableView.insertSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
            
        case let .Delete(_, index):
            tableVC.tableView.deleteSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
        }
    }
    
    // MARK: Utility
    func queueGetAuthorThumbByDetail( indexPath: NSIndexPath, key: String, parentID: NSManagedObjectID, url: NSURL ) {
        
        let authorDetailGetOperation =
            AuthorDetailWithThumbGetOperation(
                queryText: key, parentObjectID: parentID, size: "S",
                coreDataStack: self.coreDataStack ) {
                    [weak self] in
                    
                    guard let strongSelf = self else { return }
                    
                    dispatch_async( dispatch_get_main_queue() ) {
                        
                        strongSelf.tableVC.tableView.reloadRowsAtIndexPaths( [indexPath], withRowAnimation: .Automatic )
                    }
        }
        
        authorDetailGetOperation.userInitiated = true
        self.operationQueue.addOperation( authorDetailGetOperation )
    }
    
    func queueGetAuthorThumbByOLID( indexPath: NSIndexPath, key: String, url: NSURL ) {
        
        var olid = key
        if key.hasPrefix( kAuthorsPrefix ) {
            
            olid = key.substringFromIndex( key.startIndex.advancedBy( 9 ) )
        }
        
        let authorThumbnailGetOperation =
            ImageGetOperation( stringID: olid, imageKeyName: "olid", localURL: url, size: "S", type: "a" ) {
                [weak self] in
                
                if let strongSelf = self {
                    dispatch_async( dispatch_get_main_queue() ) {
                        
                        strongSelf.tableVC.tableView.reloadRowsAtIndexPaths( [indexPath], withRowAnimation: .Automatic )
                    }
                }
        }
        
        authorThumbnailGetOperation.userInitiated = true
        operationQueue.addOperation( authorThumbnailGetOperation )
    }
    
    func queueGetAuthorThumbByID( indexPath: NSIndexPath, id: Int, url: NSURL ) {
        
        let authorThumbnailGetOperation =
            ImageGetOperation( numberID: id, imageKeyName: "id", localURL: url, size: "S", type: "a" ) {
                [weak self] in
                
                if let strongSelf = self {
                    dispatch_async( dispatch_get_main_queue() ) {
                        
                        strongSelf.tableVC.tableView.reloadRowsAtIndexPaths( [indexPath], withRowAnimation: .Automatic )
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
    
    // MARK: set coordinator for new view controller
    
    func setAuthorDetailCoordinator( destVC: OLAuthorDetailViewController, indexPath: NSIndexPath ) {
        
        destVC.queryCoordinator =
            AuthorDetailCoordinator(
                operationQueue: operationQueue,
                coreDataStack: coreDataStack,
                searchInfo: objectAtIndexPath( indexPath )!,
                authorDetailVC: destVC
        )
    }
    
    
}