//
//  WorkEditionsCoordinator.swift
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

private let kWorkEditonsCache = "workEditionsCache"

private let kPageSize = 50

class WorkEditionsCoordinator: OLQueryCoordinator {
    
    typealias FetchedWorkEditionsController = FetchedResultsController< OLEditionDetail >
    
    weak var tableVC: OLWorkDetailEditionsTableViewController?

    var workEditionsGetOperation: PSOperation?
    
    fileprivate lazy var fetchedResultsController: FetchedWorkEditionsController = {
        
        let fetchRequest = OLEditionDetail.buildFetchRequest()
 
//        let secondsPerDay = NSTimeInterval( 24 * 60 * 60 )
//        let today = NSDate()
//        let lastWeek = today.dateByAddingTimeInterval( -7 * secondsPerDay )
        
        fetchRequest.predicate = NSPredicate( format: "work_key==%@", self.workDetail.key )
        
        fetchRequest.sortDescriptors = [
//                 NSSortDescriptor(key: "coversFound", ascending: false),
                 NSSortDescriptor(key: "index", ascending: true)
            ]
        fetchRequest.fetchBatchSize = 100
        
        let frc = FetchedWorkEditionsController( fetchRequest: fetchRequest,
            managedObjectContext: self.coreDataStack.mainQueueContext,
            sectionNameKeyPath: nil )
        
        frc.setDelegate( self )
        
        return frc
    }()
    
    var workDetail: OLWorkDetail
    var editionsCount = Int( kPageSize * 2 )
    var searchResults = SearchResults( start: 0, numFound: -1, pageSize: kPageSize )
    
    var highWaterMark = 0
    
    var setRetrievals = Set< Int >()
    var objectRetrievalsInProgress = Set< NSManagedObjectID >()
    
    init( workDetail: OLWorkDetail, tableVC: OLWorkDetailEditionsTableViewController, coreDataStack: OLDataStack, operationQueue: PSOperationQueue ) {
        
        self.workDetail = workDetail
        self.tableVC = tableVC
        
        if let general_search_result = workDetail.general_search_result {
            
            editionsCount = general_search_result.edition_key.count
            searchResults = SearchResults( start: 0, numFound: editionsCount, pageSize: kPageSize )
        }
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: tableVC )
    }
    
    func numberOfSections() -> Int {
        
        return fetchedResultsController.sections?.count ?? 0
    }

    func numberOfRowsInSection( _ section: Int ) -> Int {

        return fetchedResultsController.sections?[section].objects.count ?? 0
    }
    
    func objectAtIndexPath( _ indexPath: IndexPath ) -> OLEditionDetail? {

        guard let sections = fetchedResultsController.sections else {
            assertionFailure("Sections missing")
            return nil
        }
        
        let section = sections[indexPath.section]
        guard indexPath.row < section.objects.count else {
            assertionFailure( "row:\((indexPath as NSIndexPath).row) out of bounds" )
            return nil
        }

        let index = (indexPath as NSIndexPath).row
        let editionDetail = section.objects[index]
        
        if editionDetail.isProvisional || needAnotherPage( index, highWaterMark: highWaterMark ) {
            
            if nil == workEditionsGetOperation {
                
                let editionObjectID = editionDetail.objectID
                
                if !setRetrievals.contains( index / kPageSize ) {

                    workEditionsGetOperation =
                        enqueueQuery( workDetail, offset: highWaterMark, userInitiated: false, refreshControl: nil )

                } else if !objectRetrievalsInProgress.contains( editionObjectID ) {
                    
                    objectRetrievalsInProgress.insert( editionObjectID )
                    
                    workEditionsGetOperation =
                        EditionDetailGetOperation( queryText: editionDetail.key, parentObjectID: nil, coreDataStack: coreDataStack ) {
                    
                        self.workEditionsGetOperation = nil
                    }
                    
                    workEditionsGetOperation?.userInitiated = false
                    operationQueue.addOperation( workEditionsGetOperation! )
                }
            }
        }

        return editionDetail
    }
    
    @discardableResult func displayToCell( _ cell: WorkEditionTableViewCell, indexPath: IndexPath ) -> OLEditionDetail? {
        
        guard let object = objectAtIndexPath( indexPath ) else { return nil }
        
        if let tableView = tableVC?.tableView {

            cell.configure( tableView, indexPath: indexPath, key: object.key, data: object )
        
            displayThumbnail( object, cell: cell )
        }
        
        return object
    }
    
    func updateUI() {

        do {
//            NSFetchedResultsController< OLEditionDetail >.deleteCache( withName: kWorkEditonsCache )
            try fetchedResultsController.performFetch()
        }
        catch {
            print("Error in the fetched results controller: \(error).")
        }
    }
    
    func newQuery( _ workKey: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) {

        guard libraryIsReachable() else {
            
            updateHeader( "library is unreachable" )
            return
        }
        
        updateHeader( "" )
        if nil == workEditionsGetOperation {

            self.searchResults = SearchResults()
            self.highWaterMark = 0
            
            updateFooter( "fetching editions..." )
            tableVC?.coordinatorIsBusy()
           
            workEditionsGetOperation =
                enqueueQuery(
                        workDetail,
                        offset: highWaterMark,
                        userInitiated: userInitiated,
                        refreshControl: refreshControl
                    )
                
        }
    }
    
    func nextQueryPage() -> Void {
        
        guard libraryIsReachable() else {
            
            updateHeader( "library is unreachable" )
            return
        }
        
        updateHeader( "" )
        if nil == workEditionsGetOperation && highWaterMark < searchResults.numFound {
            
//            tableVC?.coordinatorIsBusy()
            updateFooter( "fetching more editions..." )
            
            workEditionsGetOperation =
                enqueueQuery(
                        workDetail,
                        offset: highWaterMark,
                        userInitiated: false,
                        refreshControl: nil
                    )
            
        }
    }
    
    func enqueueQuery( _ workDetail: OLWorkDetail, offset: Int, userInitiated: Bool, refreshControl: UIRefreshControl? ) -> PSOperation? {
        
        let page = offset / kPageSize
        guard !setRetrievals.contains( page ) else {
            
            return nil
        }
        setRetrievals.insert( page )
        
        tableVC?.coordinatorIsBusy()
        
        let workEditionsGetOperation =
            WorkEditionsGetOperation(
                    queryText: workDetail.key,
                    objectID: workDetail.objectID,
                    offset: offset, limit: kPageSize,
                    coreDataStack: coreDataStack,
                    updateResults: self.updateResults
                ) {
                
                [weak self] in

                DispatchQueue.main.async {
                        
                    if let strongSelf = self {
                        
                        refreshControl?.endRefreshing()
                        
                        strongSelf.updateFooter()
                        
                        strongSelf.tableVC?.coordinatorIsNoLongerBusy()
                        
                        strongSelf.workEditionsGetOperation = nil
                        
                        
                    }
                }
        }
    
        workEditionsGetOperation.userInitiated = userInitiated
        operationQueue.addOperation( workEditionsGetOperation )
        
        return workEditionsGetOperation
    }
    
    func refreshQuery( _ refreshControl: UIRefreshControl? ) {
        
        newQuery( workDetail.key, userInitiated: true, refreshControl: refreshControl )
    }
    
    fileprivate func needAnotherPage( _ index: Int, highWaterMark: Int ) -> Bool {

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

                strongSelf.searchResults = searchResults
                if searchResults.numFound == strongSelf.fetchedResultsController.count {
                    
                    strongSelf.highWaterMark = searchResults.numFound
                    
                } else {
                    
                    strongSelf.highWaterMark =
                        max( strongSelf.fetchedResultsController.count, searchResults.start + searchResults.pageSize )
                    
                }
            }
        }
    }
    
    fileprivate func updateHeader( _ string: String = "" ) {
        
        updateTableHeader( tableVC?.tableView, text: string )
    }
    
    fileprivate func updateFooter( _ text: String = "" ) {
        
        updateTableFooter( tableVC?.tableView, highWaterMark: highWaterMark, numFound: searchResults.numFound, text: text )
    }
    

    // MARK: install query coordinators

    func installEditionCoordinator( _ editionDetailVC: OLEditionDetailViewController, indexPath: IndexPath ) {
        
        let editionDetail = objectAtIndexPath( indexPath )!
        editionDetailVC.queryCoordinator =
            EditionDetailCoordinator(
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    searchInfo: editionDetail,
                    editionDetailVC: editionDetailVC
                )
        
        editionDetailVC.editionDetail = editionDetail
    }
    
    func installEditionDeluxeCoordinator( _ deluxeDetailVC: OLDeluxeDetailTableViewController, indexPath: IndexPath ) {
        
        let editionDetail = objectAtIndexPath( indexPath )!
        deluxeDetailVC.queryCoordinator =
            DeluxeDetailCoordinator(
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    heading: editionDetail.title,
                    deluxeData: editionDetail.deluxeData,
                    imageType: "b",
                    deluxeDetailVC: deluxeDetailVC
                )
    }
}

extension WorkEditionsCoordinator: FetchedResultsControllerDelegate {
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch(_ controller: FetchedWorkEditionsController) {
        
        guard nil != controller.fetchedObjects?.first else {
            
            newQuery( workDetail.key, userInitiated: true, refreshControl: nil )
            return
        }
        
        highWaterMark = controller.count
        updateFooter()
    }
    
    func fetchedResultsControllerWillChangeContent( _ controller: FetchedWorkEditionsController ) {
        //        tableVC?.tableView.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( _ controller: FetchedWorkEditionsController ) {
        
        if let tableView = tableVC?.tableView {
            
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
            
            //            highWaterMark = max( highWaterMark, controller.count )
            updateFooter()
        }
    }
    
    func fetchedResultsController( _ controller: FetchedWorkEditionsController,
                                   didChangeObject change: FetchedResultsObjectChange< OLEditionDetail > ) {
        
        switch change {
        case let .insert(_, indexPath):
            if !insertedSectionIndexes.contains( indexPath.section ) {
                insertedRowIndexPaths.append( indexPath )
            }
            break
            
        case let .delete(_, indexPath):
            if !deletedSectionIndexes.contains( indexPath.section ) {
                deletedRowIndexPaths.append( indexPath )
            }
            break
            
        case let .move(_, fromIndexPath, toIndexPath):
            if !insertedSectionIndexes.contains( toIndexPath.section ) {
                insertedRowIndexPaths.append( toIndexPath )
            }
            if !deletedSectionIndexes.contains( fromIndexPath.section ) {
                deletedRowIndexPaths.append( fromIndexPath )
            }
            
        case let .update(_, indexPath):
            updatedRowIndexPaths.append( indexPath )
        }
    }
    
    func fetchedResultsController(_ controller: FetchedWorkEditionsController,
                                  didChangeSection change: FetchedResultsSectionChange< OLEditionDetail >) {
        
        switch change {
        case let .insert(_, index):
            insertedSectionIndexes.add( index )
        case let .delete(_, index):
            deletedSectionIndexes.add( index )
        }
    }

}
