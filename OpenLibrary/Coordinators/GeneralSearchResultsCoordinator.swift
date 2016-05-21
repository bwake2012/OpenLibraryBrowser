//
//  TitleQueryResultsCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/10/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import UIKit
import CoreData

import BNRCoreDataStack

private let kGeneralSearchCache = "GeneralSearch"

private let kPageSize = 100

class GeneralSearchResultsCoordinator: OLQueryCoordinator, FetchedResultsControllerDelegate {
    
    typealias FetchedOLGeneralSearchResultController = FetchedResultsController< OLGeneralSearchResult >
    
    let tableVC: UITableViewController

    var generalSearchOperation: Operation?
    
    private lazy var fetchedResultsController: FetchedOLGeneralSearchResultController = {
        
        let request = NSFetchRequest(entityName: OLGeneralSearchResult.entityName)
        
        request.sortDescriptors = [
            NSSortDescriptor( key: "sequence", ascending: true ),
            NSSortDescriptor( key: "index", ascending: true )
        ]
        
        // request.fetchLimit = 100
        
        let controller =
            FetchedOLGeneralSearchResultController(
                fetchRequest: request,
                managedObjectContext: self.coreDataStack.mainQueueContext,
                sectionNameKeyPath: nil,
                cacheName: kGeneralSearchCache
        )
        
        controller.setDelegate( self )
        return controller
    }()
    
    var searchKeys = [String: String]()
    
    var searchResults = SearchResults()
    
    var highWaterMark = 0
    var nextOffset = 0
    
    init( tableVC: UITableViewController, coreDataStack: CoreDataStack, operationQueue: OperationQueue ) {
        
        self.tableVC = tableVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
        
        updateUI()
    }
    
    func numberOfSections() -> Int {
        
        return fetchedResultsController.sections?.count ?? 0
    }

    func numberOfRowsInSection( section: Int ) -> Int {

        let rows = fetchedResultsController.sections?[section].objects.count ?? 0

        return rows
    }
    
    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLGeneralSearchResult? {
        
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
    
    func displayToCell( cell: GeneralSearchResultTableViewCell, indexPath: NSIndexPath ) -> OLGeneralSearchResult? {
        
        if needAnotherPage( indexPath.row ) {
            
            nextQueryPage( highWaterMark )
        }
        
        guard let result = objectAtIndexPath( indexPath ) else { return nil }

        cell.configure( result )
        
        updateUI( result, cell: cell )
        
        // not all the Titles have photos under their OLID. Some only have them under a photo ID
//        print( "\(result.index) Title: \(result.title) has cover: \(result.hasImage)" )

        return result
    }
    
    func updateUI( searchResult: OLGeneralSearchResult, cell: GeneralSearchResultTableViewCell ) {
        
//        print( "\(searchResult.title) \(searchResult.hasImage ? "has" : "has no") cover image")
        if searchResult.hasImage {
            
            let localURL = searchResult.localURL( "S" )
            if !( cell.displayImage( localURL ) ) {
                
                let url = localURL
                let imageGetOperation =
                    ImageGetOperation( numberID: searchResult.firstImageID, imageKeyName: "id", localURL: url, size: "S", type: "b" ) {
                        
                        dispatch_async( dispatch_get_main_queue() ) {
                            
                            cell.displayImage( url )
                        }
                }
                
                imageGetOperation.userInitiated = true
                operationQueue.addOperation( imageGetOperation )
            }
        }
    }
    
    func updateUI() {

        do {
            NSFetchedResultsController.deleteCacheWithName( kGeneralSearchCache )
            try fetchedResultsController.performFetch()
        }
        catch {

            print("Error in the fetched results controller: \(error).")
        }
        
        tableVC.tableView.reloadData()
    }

    func newQuery( newSearchKeys: [String: String], userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        self.searchKeys = newSearchKeys
        
        if numberOfSections() > 0 {
            
            let top = NSIndexPath( forRow: Foundation.NSNotFound, inSection: 0 );
            tableVC.tableView.scrollToRowAtIndexPath( top, atScrollPosition: UITableViewScrollPosition.Top, animated: true );
        }
        
        if nil == generalSearchOperation {
            
            self.searchResults = SearchResults()
            self.highWaterMark = 0
            self.nextOffset = kPageSize
            
            generalSearchOperation =
                GeneralSearchOperation(
                        queryParms: newSearchKeys,
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
                            strongSelf.generalSearchOperation = nil
                        }
                    }
            
            generalSearchOperation!.userInitiated = userInitiated
            operationQueue.addOperation( generalSearchOperation! )
        }
    }
    
    func nextQueryPage( offset: Int ) -> Void {
        
        if !searchKeys.isEmpty && nil == self.generalSearchOperation {
            
            nextOffset = offset + kPageSize
            generalSearchOperation =
                GeneralSearchOperation(
                        queryParms: self.searchKeys,
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
                        
                        strongSelf.generalSearchOperation = nil
                    }
            }

            generalSearchOperation!.userInitiated = false
            operationQueue.addOperation( generalSearchOperation! )
        }
    }
    
    func clearQuery() {
        
        let queryClearOperation = GeneralSearchResultsDeleteOperation( coreDataStack: coreDataStack )
        
        queryClearOperation.userInitiated = false
        operationQueue.addOperation( queryClearOperation )
            
    }
    
    private func needAnotherPage( index: Int ) -> Bool {
        
        return
            nil == self.generalSearchOperation &&
            !searchKeys.isEmpty &&
            highWaterMark < searchResults.numFound &&
            index >= ( self.fetchedResultsController.count - 1 )
    }
    
    // MARK: SearchResultsUpdater
    func updateResults(searchResults: SearchResults) -> Void {
        
        self.searchResults = searchResults
        self.highWaterMark = searchResults.start + searchResults.pageSize
    }
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch(controller: FetchedResultsController< OLGeneralSearchResult >) {

        if searchKeys.isEmpty {
            self.highWaterMark = fetchedResultsController.count
            self.searchResults = SearchResults( start: 0, numFound: highWaterMark, pageSize: 100 )
            tableVC.tableView.reloadData()
        }
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedResultsController< OLGeneralSearchResult > ) {
        tableVC.tableView.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedResultsController< OLGeneralSearchResult > ) {
        tableVC.tableView.endUpdates()
    }
    
    func fetchedResultsController( controller: FetchedResultsController< OLGeneralSearchResult >,
        didChangeObject change: FetchedResultsObjectChange< OLGeneralSearchResult > ) {
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
    
    func fetchedResultsController(controller: FetchedResultsController< OLGeneralSearchResult >,
        didChangeSection change: FetchedResultsSectionChange< OLGeneralSearchResult >) {
            switch change {
            case let .Insert(_, index):
                tableVC.tableView.insertSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
                
            case let .Delete(_, index):
                tableVC.tableView.deleteSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
            }
    }
    
    // MARK: Utility
    func queueGetTitleThumbByID( indexPath: NSIndexPath, id: Int, url: NSURL ) {
        
        let TitleThumbnailGetOperation =
            ImageGetOperation( numberID: id, imageKeyName: "id", localURL: url, size: "S", type: "a" ) {
                [weak self] in
                
                if let strongSelf = self {
                    dispatch_async( dispatch_get_main_queue() ) {
                        
                        strongSelf.tableVC.tableView.reloadRowsAtIndexPaths( [indexPath], withRowAnimation: .Automatic )
                    }
                }
        }
        
        TitleThumbnailGetOperation.userInitiated = true
        operationQueue.addOperation( TitleThumbnailGetOperation )
    }
    
    // MARK: set coordinator for view controller
    
    func installAuthorDetailCoordinator( destVC: OLAuthorDetailViewController, indexPath: NSIndexPath ) {
        
        destVC.queryCoordinator =
            AuthorDetailCoordinator(
                operationQueue: operationQueue,
                coreDataStack: coreDataStack,
                searchInfo: objectAtIndexPath( indexPath )!,
                authorDetailVC: destVC
        )
    }
    
    func installWorkDetailCoordinator( destVC: OLWorkDetailViewController, indexPath: NSIndexPath ) {
        
        if let searchResult = objectAtIndexPath( indexPath ) {
            
            destVC.queryCoordinator =
                WorkDetailCoordinator(
                    authorNames: searchResult.author_name,
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    workKey: searchResult.key,
                    workDetailVC: destVC
            )
            
        }
    }
}
