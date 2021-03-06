//
//  SearchResultsCoordinator.swift
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

private let kTitleSearchCache = "titleNameSearch"

private let kPageSize = 100

class SearchResultsCoordinator: OLQueryCoordinator, FetchedResultsControllerDelegate {
    
    typealias FetchedOLAuthorSearchResultController = FetchedResultsController< OLAuthorSearchResult >
    typealias FetchedOLTitleSearchResultController = FetchedResultsController< OLTitleSearchResult >
    
    var searchType = SearchType.searchAuthor
    var searchOperation: Operation?
    var searchText = ""

    let tableVC: UITableViewController

    private lazy var fetchedAuthorResultsController: FetchedOLAuthorSearchResultController = {
        
        return self.fetchedAuthorSearchResultsController()
    }()
    
    func fetchedAuthorSearchResultsController() -> FetchedOLAuthorSearchResultController {

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
    }
    
    private lazy var fetchedTitleResultsController: FetchedOLTitleSearchResultController = {
        
        return self.fetchedTitleSearchResultsController()
    }()
    
    func fetchedTitleSearchResultsController() -> FetchedOLTitleSearchResultController {
        
        let request = NSFetchRequest(entityName: OLTitleSearchResult.entityName)
        
        request.sortDescriptors = [
            NSSortDescriptor( key: "sequence", ascending: true ),
            NSSortDescriptor( key: "index", ascending: true )
        ]
        
        // request.fetchLimit = 100
        
        let controller =
            FetchedOLTitleSearchResultController(
                    fetchRequest: request,
                    managedObjectContext: self.coreDataStack.mainQueueContext,
                    sectionNameKeyPath: nil,
                    cacheName: kTitleSearchCache
                )
        
        controller.setDelegate( self )
        return controller
    }
    
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
        
        if .searchAuthor == searchType {
            return fetchedAuthorResultsController.sections?.count ?? 1
        } else if .searchTitle == searchType {
            return fetchedTitleResultsController.sections?.count ?? 1
        } else {
            
            return 1
        }
    }

    func numberOfRowsInSection( section: Int ) -> Int {

        var rows = 0
        if .searchAuthor == searchType {
            rows = fetchedAuthorResultsController.sections?[section].objects.count ?? 0
        } else if .searchTitle == searchType {
            rows = fetchedAuthorResultsController.sections?[section].objects.count ?? 0
        }

        return rows
    }
    
    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLAuthorSearchResult? {
        
        if 0 == searchResults.numFound { return nil }
        
        if .searchAuthor == searchType {
            
            guard let sections = fetchedAuthorResultsController.sections else {
                assertionFailure("Author sections missing")
                return nil
            }
            
            let section = sections[indexPath.section]
            if indexPath.row >= section.objects.count {

                return nil

            } else {
                
                return section.objects[indexPath.row]
            }
        }
        
        return nil
    }
    
    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLTitleSearchResult? {
 
        if .searchTitle == searchType {
            
            guard let sections = fetchedTitleResultsController.sections else {
                assertionFailure("Title sections missing")
                return nil
            }
            
            let section = sections[indexPath.section]
            if indexPath.row >= section.objects.count {
                
                return nil
                
            } else {
                
                return section.objects[indexPath.row]
            }
        }
        
        return nil
    }
    
    func displayToCell( cell: AuthorSearchResultTableViewCell, indexPath: NSIndexPath ) -> OLAuthorSearchResult? {
        
        if needAnotherPage( indexPath.row ) {
            
            nextQueryPage( highWaterMark )
        }
        
        guard let result: OLAuthorSearchResult = objectAtIndexPath( indexPath ) else { return nil }

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
    
    func displayToCell( titleCell: TitleSearchResultTableViewCell, indexPath: NSIndexPath ) -> OLTitleSearchResult? {
        
        if needAnotherPage( indexPath.row ) {
            
            nextQueryPage( highWaterMark )
        }
        
        guard let result: OLTitleSearchResult = objectAtIndexPath( indexPath ) else { return nil }
        
        titleCell.configure( result )
        
        updateUI( result, cell: titleCell )
        
        // not all the Titles have photos under their OLID. Some only have them under a photo ID
        print( "\(result.index) Title: \(result.title) has cover: \(result.hasImage)" )
        
        return result
    }
    
    func updateUI( searchResult: OLTitleSearchResult, cell: TitleSearchResultTableViewCell ) {
        
        if searchResult.hasImage {
            
            let localURL = searchResult.localURL( "S" )
            if !( cell.displayImage( localURL ) ) {
                
                let url = localURL
                let imageGetOperation =
                    ImageGetOperation( numberID: searchResult.firstImageID, imageKeyName: "id", localURL: url, size: "S", type: "a" ) {
                        
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
            if .searchAuthor == searchType {
                NSFetchedResultsController.deleteCacheWithName( kAuthorSearchCache )
                try fetchedAuthorResultsController.performFetch()
            } else if .searchTitle == searchType {
                NSFetchedResultsController.deleteCacheWithName( kTitleSearchCache )
                try fetchedTitleResultsController.performFetch()
            } else {
                
                assert( .searchAuthor == searchType || .searchTitle == searchType)
            }
        }
        catch {

            print("Error in the \(searchType) fetched results controller: \(error).")
        }
        
        tableVC.tableView.reloadData()
    }

    func newQuery( searchText: String, searchType: SearchType, userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        if self.searchResults.numFound > 0 {
            
            tableVC.tableView.scrollToRowAtIndexPath( NSIndexPath( forRow: 0, inSection: 0 ), atScrollPosition: .Top, animated: false )
        }
        
        if searchText != self.searchText && nil == searchOperation {
            
            self.searchResults = SearchResults()
            self.searchText = searchText
            self.highWaterMark = 0
            self.nextOffset = kPageSize
            
            if .searchAuthor == searchType {
                searchOperation =
                    AuthorNameSearchOperation(
                            queryText: searchText,
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
                                strongSelf.searchOperation = nil
                            }
                        }
                
                searchOperation!.userInitiated = userInitiated
                operationQueue.addOperation( searchOperation! )

            } else if .searchTitle == searchType {
                
                searchOperation =
                    TitleSearchOperation(
                        queryText: searchText,
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
                            strongSelf.searchOperation = nil
                        }
                }
                
                searchOperation!.userInitiated = userInitiated
                operationQueue.addOperation( searchOperation! )
            }
        }
    }
    
    func nextQueryPage( offset: Int ) -> Void {
        
        if !authorName.isEmpty && nil == self.searchOperation {
            
            nextOffset = offset + kPageSize
            searchOperation =
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
                        
                        strongSelf.searchOperation = nil
                    }
            }
            
            searchOperation!.userInitiated = false
            operationQueue.addOperation( searchOperation! )
        }
    }
    
    func clearQuery() {
        
        let queryClearOperation = AuthorSearchResultsDeleteOperation( coreDataStack: coreDataStack )
        
        queryClearOperation.userInitiated = false
        operationQueue.addOperation( queryClearOperation )
            
    }
    
    private func needAnotherPage( index: Int ) -> Bool {
        
        if
            nil == self.searchOperation &&
            !authorName.isEmpty &&
                highWaterMark < searchResults.numFound {
            if .searchAuthor == searchType {
                return index >= self.fetchedAuthorResultsController.count - 1
            } else if .searchTitle == searchType {
                return index >= self.fetchedTitleResultsController.count - 1
            }
        }
        
        return false
    }
    
    // MARK: SearchResultsUpdater
    func updateResults(searchResults: SearchResults) -> Void {
        
        self.searchResults = searchResults
        self.highWaterMark = searchResults.start + searchResults.pageSize
    }
    
    // MARK: FetchedOLAuthorSearchResultController
    func fetchedResultsControllerDidPerformFetch( controller: FetchedOLAuthorSearchResultController ) {

        if authorName.isEmpty {
            self.highWaterMark = controller.count
            self.searchResults = SearchResults( start: 0, numFound: highWaterMark, pageSize: 100 )
            tableVC.tableView.reloadData()
        }
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedOLAuthorSearchResultController ) {
        tableVC.tableView.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedOLAuthorSearchResultController ) {
        tableVC.tableView.endUpdates()
    }
    
    func fetchedResultsController( controller: FetchedOLAuthorSearchResultController,
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
    
    func fetchedResultsController(controller: FetchedOLAuthorSearchResultController,
        didChangeSection change: FetchedResultsSectionChange< OLAuthorSearchResult >) {
            switch change {
            case let .Insert(_, index):
                tableVC.tableView.insertSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
                
            case let .Delete(_, index):
                tableVC.tableView.deleteSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
            }
    }
    
    // MARK: FetchedOLTitleSearchResultController
    func fetchedResultsControllerDidPerformFetch( controller: FetchedOLTitleSearchResultController ) {
        
        if authorName.isEmpty {
            self.highWaterMark = controller.count
            self.searchResults = SearchResults( start: 0, numFound: highWaterMark, pageSize: 100 )
            tableVC.tableView.reloadData()
        }
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedOLTitleSearchResultController ) {
        tableVC.tableView.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedOLTitleSearchResultController ) {
        tableVC.tableView.endUpdates()
    }
    
    func fetchedResultsController( controller: FetchedOLTitleSearchResultController,
                                   didChangeObject change: FetchedResultsObjectChange< OLTitleSearchResult > ) {
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
    
    func fetchedResultsController(controller: FetchedOLTitleSearchResultController,
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
