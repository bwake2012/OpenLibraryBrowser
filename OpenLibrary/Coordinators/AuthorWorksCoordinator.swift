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

//import BNRCoreDataStack
import PSOperations

private let kWorksByAuthorCache = "worksByAuthor"

private let kPageSize = 100
    
class AuthorWorksCoordinator: OLQueryCoordinator {
    
    typealias FetchedOLWorkDetailController = NSFetchedResultsController< OLWorkDetail >
    
    weak var authorWorksTableVC: OLAuthorDetailWorksTableViewController?

    var authorWorksGetOperation: PSOperation?
    
    lazy var fetchedResultsController: FetchedOLWorkDetailController = self.BuildFetchedResultsController()
    
    var authorKey: String
    var authorDetail: OLAuthorDetail?
    var searchResults = SearchResults( start: 0, numFound: -1, pageSize: kPageSize )

    var highWaterMark = 0
    var setRetrievals = Set< Int >()
    var objectRetrievalsInProgress = Set< NSManagedObjectID >()
    
    init( authorKey: String, authorWorksTableVC: OLAuthorDetailWorksTableViewController, dataStack: OLDataStack, operationQueue: PSOperationQueue ) {
        
        self.authorKey = authorKey

        self.authorWorksTableVC = authorWorksTableVC
        
        super.init( operationQueue: operationQueue, dataStack: dataStack, viewController: authorWorksTableVC )
    }
    
    func numberOfSections() -> Int {
        
        return fetchedResultsController.sections?.count ?? 0
    }

    func numberOfRowsInSection( _ section: Int ) -> Int {

        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func objectAtIndexPath( _ indexPath: IndexPath ) -> OLWorkDetail? {
        
        guard let sections = fetchedResultsController.sections else {
            assertionFailure("Sections missing")
            return nil
        }
        
        let section = sections[indexPath.section]
        guard let itemsInSection = section.objects as? [OLWorkDetail] else {
            fatalError("Missing items")
        }
        
        guard indexPath.row < itemsInSection.count else {
            
            return nil
        }
        
        let index = (indexPath as NSIndexPath).row
        let workDetail = itemsInSection[index]
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
                            currentObjectID: workObjectID,
                            dataStack: dataStack,
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
    
    @discardableResult func displayToCell( _ cell: AuthorWorksTableViewCell, indexPath: IndexPath ) -> OLWorkDetail? {
        
        guard let workDetail = objectAtIndexPath( indexPath ) else { return nil }
        
        cell.configure( authorWorksTableVC!.tableView, indexPath: indexPath, key: workDetail.key, data: workDetail )
        
//        print( "work: \(result.title) has covers: \(!result.covers.isEmpty)" )
        
        displayThumbnail( workDetail, cell: cell )
        
        return workDetail
    }
    
    func updateUI() {

        do {
//            NSFetchedResultsController< OLWorkDetail >.deleteCache( withName: kWorksByAuthorCache )
            try fetchedResultsController.performFetch()

            controllerDidPerformFetch( fetchedResultsController )
        }
        catch {
            print("Error in the fetched results controller: \(error).")
        }
    }

    func newQuery( _ authorKey: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) {

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
    
    func enqueueQuery( _ authorKey: String, offset: Int, userInitiated: Bool, refreshControl: UIRefreshControl? ) -> PSOperation {
        
        authorWorksTableVC?.coordinatorIsBusy()
        
        let page = offset / kPageSize
        setRetrievals.insert( page )
        
        let authorWorksGetOperation =
            AuthorWorksGetOperation(
                queryText: authorKey,
                parentObjectID: nil,
                offset: page * kPageSize, limit: kPageSize,
                dataStack: dataStack,
                updateResults: self.updateResults
            ) {
                [weak self] in
                
                DispatchQueue.main.async {
                        
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
    
    func refreshQuery( _ refreshControl: UIRefreshControl? ) {
        
        newQuery( authorKey, userInitiated: true, refreshControl: refreshControl )
    }
    
    fileprivate func needAnotherPage( _ index: Int ) -> Bool {
        
        return
            !setRetrievals.contains( index / kPageSize ) &&
            index <= highWaterMark - kPageSize / 5 &&
            highWaterMark < searchResults.numFound
    }
    
    // MARK: SearchResultsUpdater
    func updateResults(_ searchResults: SearchResults) -> Void {
        
        DispatchQueue.main.async {
            [weak self] in
            
            if let strongSelf = self {
                
                strongSelf.highWaterMark = strongSelf.numberOfRowsInSection( 0 )
                let numFound = max( searchResults.numFound, strongSelf.highWaterMark )
                strongSelf.searchResults =
                    SearchResults( start: searchResults.start, numFound: numFound, pageSize: searchResults.pageSize )
            }
        }
    }
    
    fileprivate func updateHeader( _ string: String = "" ) {
        
        updateTableHeader( authorWorksTableVC?.tableView, text: string )
    }
    
    fileprivate func updateFooter( _ text: String = "" ) {
        
        updateTableFooter( authorWorksTableVC?.tableView, highWaterMark: highWaterMark, numFound: searchResults.numFound, text: text )
    }
    
    // MARK: install Query Coordinators
    
    func installWorkDetailCoordinator( _ destVC: OLWorkDetailViewController, indexPath: IndexPath ){
    
        guard let workDetail = objectAtIndexPath( indexPath ) else {
            
            fatalError( "work detail not found at: \(indexPath)" )
        }

        destVC.queryCoordinator =
            WorkDetailCoordinator(
                    operationQueue: self.operationQueue,
                    dataStack: self.dataStack,
                    workDetail: workDetail,
                    editionKeys: [],
                    workDetailVC: destVC
                )

    }
}

extension AuthorWorksCoordinator: NSFetchedResultsControllerDelegate {
    
    func BuildFetchedResultsController() -> FetchedOLWorkDetailController {
        
        let fetchRequest = OLWorkDetail.buildFetchRequest()
        let key = authorKey
        
        let secondsPerDay = TimeInterval( 24 * 60 * 60 )
        let today = Date()
        let lastWeek = today.addingTimeInterval( -7 * secondsPerDay )
        
        fetchRequest.predicate = NSPredicate( format: "author_key==%@ && retrieval_date > %@", key, lastWeek as NSDate )
        
        fetchRequest.sortDescriptors =
            [
                //                NSSortDescriptor(key: "coversFound", ascending: false),
                NSSortDescriptor(key: "index", ascending: true)
        ]
        fetchRequest.fetchBatchSize = 100
        
        let frc = FetchedOLWorkDetailController( fetchRequest: fetchRequest,
                                                 managedObjectContext: self.dataStack.mainQueueContext,
                                                 sectionNameKeyPath: nil,
                                                 cacheName: nil )
        
        frc.delegate = self
        return frc
    }
    
    // MARK: FetchedResultsControllerDelegate
    func controllerDidPerformFetch( _ controller: FetchedOLWorkDetailController ) {
        
        guard nil != controller.fetchedObjects?.first else {
            
            newQuery( authorKey, userInitiated: true, refreshControl: nil )
            return
        }
        
        highWaterMark = numberOfRowsInSection( 0 )
        updateFooter()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        if let tableView = authorWorksTableVC?.tableView {
            
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
            
            highWaterMark = max( highWaterMark, numberOfRowsInSection( 0 ) )
            updateFooter()
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
            fatalError("Unexpected NSFetchedResultsChangeType")
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
