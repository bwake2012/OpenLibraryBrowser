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
import PSOperations

private let kWorksByAuthorCache = "worksByAuthor"

private let kPageSize = 100
    
class AuthorWorksCoordinator: OLQueryCoordinator {
    
    typealias FetchedOLWorkDetailController = FetchedResultsController< OLWorkDetail >
    
    weak var authorWorksTableVC: OLAuthorDetailWorksTableViewController?

    var authorWorksGetOperation: Operation?
    
    lazy var fetchedResultsController: FetchedOLWorkDetailController = self.BuildFetchedResultsController()
    
    var authorKey: String
    var authorDetail: OLAuthorDetail?
    var searchResults = SearchResults( start: 0, numFound: -1, pageSize: kPageSize )

    var highWaterMark = 0
    var setRetrievals = Set< Int >()
    var objectRetrievalsInProgress = Set< NSManagedObjectID >()
    
    init( authorKey: String, authorWorksTableVC: OLAuthorDetailWorksTableViewController, coreDataStack: CoreDataStack, operationQueue: OperationQueue ) {
        
        self.authorKey = authorKey

        self.authorWorksTableVC = authorWorksTableVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: authorWorksTableVC )
    }
    
    func numberOfSections() -> Int {
        
        return fetchedResultsController.sections?.count ?? 0
    }

    func numberOfRowsInSection( section: Int ) -> Int {

        return fetchedResultsController.sections?[section].objects.count ?? 0
    }
    
    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLWorkDetail? {
        
        guard let sections = fetchedResultsController.sections else {
            assertionFailure("Sections missing")
            return nil
        }
        
        let section = sections[indexPath.section]
        
        guard indexPath.row < section.objects.count else {
            
            return nil
        }
        
        let index = indexPath.row
        let workDetail = section.objects[index]
        if workDetail.isProvisional || needAnotherPage( index ) {
            
            if nil == authorWorksGetOperation {

                let workObjectID = workDetail.objectID

                if !setRetrievals.contains( index / kPageSize ) {
                
                    authorWorksGetOperation =
                        enqueueQuery( authorKey, offset: index, userInitiated: false, refreshControl: nil )
                    
                } else if !objectRetrievalsInProgress.contains( workObjectID ) {
                    
                    objectRetrievalsInProgress.insert( workObjectID )
                    
                    authorWorksGetOperation =
                        WorkDetailGetOperation(
                            queryText: workDetail.key,
                            coreDataStack: coreDataStack,
                            resultHandler: nil
                        ) {
                            
                            self.authorWorksGetOperation = nil
                        }
                    
                    authorWorksGetOperation?.userInitiated = false
                    operationQueue.addOperation( authorWorksGetOperation! )
                }
            }
        }
        
        return workDetail
    }
    
    func displayToCell( cell: AuthorWorksTableViewCell, indexPath: NSIndexPath ) -> OLWorkDetail? {
        
        guard let workDetail = objectAtIndexPath( indexPath ) else { return nil }
        
        cell.configure( authorWorksTableVC!.tableView, indexPath: indexPath, key: workDetail.key, data: workDetail )
        
//        print( "work: \(result.title) has covers: \(!result.covers.isEmpty)" )
        
        displayThumbnail( workDetail, cell: cell )
        
        return workDetail
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

        guard libraryIsReachable() else {
            
            updateHeader( "library is unreachable" )
            return
        }
        
        updateHeader( "" )
        if nil == authorWorksGetOperation {
            self.searchResults = SearchResults()
            self.highWaterMark = 0
            
            updateFooter( "fetching author works..." )
            authorWorksGetOperation =
                enqueueQuery(
                        authorKey,
                        offset: highWaterMark, 
                        userInitiated: false,
                        refreshControl: nil
                    )
        }
    }
    
    func nextQueryPage() -> Void {
        
        guard libraryIsReachable() else {
            
            updateHeader( "library is unreachable" )
            return
        }
        
        updateHeader( "" )
        if nil == authorWorksGetOperation && ( -1 == searchResults.numFound || highWaterMark < searchResults.numFound ) {
            
            updateFooter( "fetching more author works..." )
            
            authorWorksGetOperation =
                enqueueQuery(
                        authorKey,
                        offset: highWaterMark,
                        userInitiated: false,
                        refreshControl: nil
                    )
         }
    }
    
    func enqueueQuery( authorKey: String, offset: Int, userInitiated: Bool, refreshControl: UIRefreshControl? ) -> Operation {
        
        authorWorksTableVC?.coordinatorIsBusy()
        
        let page = offset / kPageSize
        setRetrievals.insert( page )
        
        let authorWorksGetOperation =
            AuthorWorksGetOperation(
                queryText: authorKey,
                parentObjectID: nil,
                offset: page * kPageSize, limit: kPageSize,
                coreDataStack: coreDataStack,
                updateResults: self.updateResults
            ) {
                [weak self] in
                
                dispatch_async( dispatch_get_main_queue() ) {
                        
                    if let strongSelf = self {
                        
                        refreshControl?.endRefreshing()
                        
                        strongSelf.authorWorksTableVC?.coordinatorIsNoLongerBusy()
                        
                        strongSelf.updateFooter()
                        
                        strongSelf.authorWorksGetOperation = nil
                    }
                }
        }
        
        authorWorksGetOperation.userInitiated = userInitiated
        operationQueue.addOperation( authorWorksGetOperation )
        
        return authorWorksGetOperation
    }
    
    func refreshQuery( refreshControl: UIRefreshControl? ) {
        
        newQuery( authorKey, userInitiated: true, refreshControl: refreshControl )
    }
    
    private func needAnotherPage( index: Int ) -> Bool {
        
        return
            !setRetrievals.contains( index / kPageSize ) &&
            index <= highWaterMark - kPageSize / 5 &&
            highWaterMark < searchResults.numFound
    }
    
    // MARK: SearchResultsUpdater
    func updateResults(searchResults: SearchResults) -> Void {
        
        dispatch_async( dispatch_get_main_queue() ) {
            [weak self] in
            
            if let strongSelf = self {
                
                let numFound = max( searchResults.numFound, strongSelf.fetchedResultsController.count )
                strongSelf.searchResults =
                    SearchResults( start: searchResults.start, numFound: searchResults.pageSize, pageSize: numFound )
                strongSelf.highWaterMark =
                    max( strongSelf.fetchedResultsController.count, numFound )
            }
        }
    }
    
    private func updateHeader( string: String = "" ) {
        
        updateTableHeader( authorWorksTableVC?.tableView, text: string )
    }
    
    private func updateFooter( text: String = "" ) {
        
        updateTableFooter( authorWorksTableVC?.tableView, highWaterMark: highWaterMark, numFound: searchResults.numFound, text: text )
    }
    
    // MARK: Utility
    func BuildFetchedResultsController() -> FetchedOLWorkDetailController {
        
        let fetchRequest = NSFetchRequest( entityName: OLWorkDetail.entityName )
        let key = authorKey
        
        let secondsPerDay = NSTimeInterval( 24 * 60 * 60 )
        let today = NSDate()
        let lastWeek = today.dateByAddingTimeInterval( -7 * secondsPerDay )
        
        fetchRequest.predicate = NSPredicate( format: "author_key==%@ && retrieval_date > %@", "\(key)", lastWeek )
        
        fetchRequest.sortDescriptors =
            [
                //                NSSortDescriptor(key: "coversFound", ascending: false),
                NSSortDescriptor(key: "index", ascending: true)
            ]
        fetchRequest.fetchBatchSize = 100
        
        let frc = FetchedOLWorkDetailController( fetchRequest: fetchRequest,
                                                 managedObjectContext: self.coreDataStack.mainQueueContext,
                                                 sectionNameKeyPath: nil )
        
        frc.setDelegate( self )
        return frc
    }

    // MARK: install Query Coordinators
    
    func installWorkDetailCoordinator( destVC: OLWorkDetailViewController, indexPath: NSIndexPath ){
    
        guard let workDetail = objectAtIndexPath( indexPath ) else {
            
            fatalError( "work detail not found at: \(indexPath)" )
        }

        destVC.queryCoordinator =
            WorkDetailCoordinator(
                    operationQueue: self.operationQueue,
                    coreDataStack: self.coreDataStack,
                    workDetail: workDetail,
                    editionKeys: [],
                    workDetailVC: destVC
                )

    }
}

extension AuthorWorksCoordinator: FetchedResultsControllerDelegate {
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch( controller: FetchedOLWorkDetailController ) {
        
        guard let workDetail = controller.fetchedObjects?.first else {
            
            newQuery( authorKey, userInitiated: true, refreshControl: nil )
            return
        }
        
        highWaterMark = controller.count
        updateFooter()
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedOLWorkDetailController ) {
        //        authorWorksTableVC?.tableView.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedOLWorkDetailController ) {
        
        if let tableView = authorWorksTableVC?.tableView {
            
            tableView.beginUpdates()
            
            tableView.deleteSections( deletedSectionIndexes, withRowAnimation: .Automatic )
            tableView.insertSections( insertedSectionIndexes, withRowAnimation: .Automatic )
            
            tableView.deleteRowsAtIndexPaths( deletedRowIndexPaths, withRowAnimation: .Left )
            tableView.insertRowsAtIndexPaths( insertedRowIndexPaths, withRowAnimation: .Right )
            tableView.reloadRowsAtIndexPaths( updatedRowIndexPaths, withRowAnimation: .Automatic )
            
            tableView.endUpdates()
            
            // nil out the collections so they are ready for their next use.
            self.insertedSectionIndexes = NSMutableIndexSet()
            self.deletedSectionIndexes = NSMutableIndexSet()
            
            self.deletedRowIndexPaths = []
            self.insertedRowIndexPaths = []
            self.updatedRowIndexPaths = []
            
            highWaterMark = max( highWaterMark, controller.count )
            updateFooter()
        }
    }
    
    func fetchedResultsController( controller: FetchedOLWorkDetailController,
                                   didChangeObject change: FetchedResultsObjectChange< OLWorkDetail > ) {
        
        switch change {
        case let .Insert(_, indexPath):
            if !insertedSectionIndexes.containsIndex( indexPath.section ) {
                insertedRowIndexPaths.append( indexPath )
            }
            break
            
        case let .Delete(_, indexPath):
            if !deletedSectionIndexes.containsIndex( indexPath.section ) {
                deletedRowIndexPaths.append( indexPath )
            }
            break
            
        case let .Move(_, fromIndexPath, toIndexPath):
            if !insertedSectionIndexes.containsIndex( toIndexPath.section ) {
                insertedRowIndexPaths.append( toIndexPath )
            }
            if !deletedSectionIndexes.containsIndex( fromIndexPath.section ) {
                deletedRowIndexPaths.append( fromIndexPath )
            }
            
        case let .Update(_, indexPath):
            updatedRowIndexPaths.append( indexPath )
        }
    }
    
    func fetchedResultsController(controller: FetchedOLWorkDetailController,
                                  didChangeSection change: FetchedResultsSectionChange< OLWorkDetail >) {
        
        switch change {
        case let .Insert(_, index):
            insertedSectionIndexes.addIndex( index )
        case let .Delete(_, index):
            deletedSectionIndexes.addIndex( index )
        }
    }
    

}
