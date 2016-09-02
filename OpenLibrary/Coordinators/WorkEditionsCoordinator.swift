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

class WorkEditionsCoordinator: OLQueryCoordinator, FetchedResultsControllerDelegate {
    
    typealias FetchedWorkEditionsController = FetchedResultsController< OLEditionDetail >
    
    weak var tableVC: OLWorkDetailEditionsTableViewController?

    var workEditionsGetOperation: Operation?
    
    private lazy var fetchedResultsController: FetchedWorkEditionsController = {
        
        let fetchRequest = NSFetchRequest( entityName: OLEditionDetail.entityName )
 
//        let secondsPerDay = NSTimeInterval( 24 * 60 * 60 )
//        let today = NSDate()
//        let lastWeek = today.dateByAddingTimeInterval( -7 * secondsPerDay )
        
        fetchRequest.predicate = NSPredicate( format: "work_key==%@", "\(self.workKey)" )
        
        fetchRequest.sortDescriptors =
            [NSSortDescriptor(key: "coversFound", ascending: false),
             NSSortDescriptor(key: "index", ascending: true)]
        fetchRequest.fetchBatchSize = 100
        
        let frc = FetchedWorkEditionsController( fetchRequest: fetchRequest,
            managedObjectContext: self.coreDataStack.mainQueueContext,
            sectionNameKeyPath: nil )
        
        frc.setDelegate( self )
        
        return frc
    }()
    
    let withCoversOnly: Bool
    
    var workKey = ""
    var editionsCount = Int( kPageSize * 2 )
    var searchResults = SearchResults()
    
    var highWaterMark = 0
    
    init( workKey: String, withCoversOnly: Bool, tableVC: OLWorkDetailEditionsTableViewController, coreDataStack: CoreDataStack, operationQueue: OperationQueue ) {
        
        self.workKey = workKey
        self.withCoversOnly = withCoversOnly
//        self.worksCount = searchInfo.work_count
        self.tableVC = tableVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: tableVC )
    }
    
    func numberOfSections() -> Int {
        
        return fetchedResultsController.sections?.count ?? 0
    }

    func numberOfRowsInSection( section: Int ) -> Int {

        return fetchedResultsController.sections?[section].objects.count ?? 0
    }
    
    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLEditionDetail? {
        
        guard let sections = fetchedResultsController.sections else {
            assertionFailure("Sections missing")
            return nil
        }
        
        let section = sections[indexPath.section]
        guard indexPath.row < section.objects.count else {
            assertionFailure( "row:\(indexPath.row) out of bounds" )
            return nil
        }

        return section.objects[indexPath.row]
    }
    
    func displayToCell( cell: WorkEditionTableViewCell, indexPath: NSIndexPath ) -> OLEditionDetail? {
        
//        if needAnotherPage( indexPath.row, highWaterMark: highWaterMark ) {
//            
//            nextQueryPage( highWaterMark )
//        }

        guard let object = objectAtIndexPath( indexPath ) else { return nil }
        
        if let tableView = tableVC?.tableView {

            cell.configure( tableView, key: object.key, data: object )
        
            displayThumbnail( object, cell: cell )
        }
        
        return object
    }
    
    func updateUI() {

        do {
            NSFetchedResultsController.deleteCacheWithName( kWorkEditonsCache )
            try fetchedResultsController.performFetch()
        }
        catch {
            print("Error in the fetched results controller: \(error).")
        }
    }
    
    func newQuery( workKey: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) {

        guard libraryIsReachable() else {
            
            updateFooter( "library is unreachable" )
            return
        }
        
        if nil == workEditionsGetOperation {
            self.searchResults = SearchResults()
            self.workKey = workKey
            self.highWaterMark = 0
            
            tableVC?.coordinatorIsBusy()
            updateFooter( "fetching editions..." )
            
            workEditionsGetOperation =
                WorkEditionsGetOperation(
                        queryText: workKey,
                        offset: 0, limit: kPageSize,
                        withCoversOnly: withCoversOnly,
                        coreDataStack: coreDataStack,
                        updateResults: self.updateResults
                    ) {

                        [weak self] in
                        if let strongSelf = self {
                            dispatch_async( dispatch_get_main_queue() ) {
                                
                                    refreshControl?.endRefreshing()
                                
                                    strongSelf.updateFooter()
                                
                                    strongSelf.tableVC?.coordinatorIsNoLongerBusy()
                                
                                    strongSelf.workEditionsGetOperation = nil
                                }
                        }
                    }
            
            workEditionsGetOperation!.userInitiated = userInitiated
            operationQueue.addOperation( workEditionsGetOperation! )
        }
    }
    
    func nextQueryPage() -> Void {
        
        guard libraryIsReachable() else {
            
            updateFooter( "library is unreachable" )
            return
        }
        
        if nil == workEditionsGetOperation && !workKey.isEmpty && highWaterMark < searchResults.numFound {
            
//            tableVC?.coordinatorIsBusy()
            updateFooter( "fetching more editions..." )
            
            workEditionsGetOperation =
                WorkEditionsGetOperation(
                        queryText: self.workKey,
                        offset: highWaterMark, limit: kPageSize,
                        withCoversOnly: withCoversOnly,
                        coreDataStack: coreDataStack,
                        updateResults: self.updateResults
                    ) {
                
                        [weak self] in
                        if let strongSelf = self {
                            
                            strongSelf.updateFooter()
                            
                            strongSelf.tableVC?.coordinatorIsNoLongerBusy()
                            
                            strongSelf.workEditionsGetOperation = nil
                        }
                    }
            
            workEditionsGetOperation!.userInitiated = false
            operationQueue.addOperation( workEditionsGetOperation! )
        }
    }
    
    func refreshQuery( refreshControl: UIRefreshControl? ) {
        
        newQuery( self.workKey, userInitiated: true, refreshControl: refreshControl )
    }
    
    private func needAnotherPage( index: Int, highWaterMark: Int ) -> Bool {
        
        return
            nil == workEditionsGetOperation &&
            !workKey.isEmpty &&
            highWaterMark < searchResults.numFound &&
            index >= ( highWaterMark - ( searchResults.pageSize / 4 ) )
    }
    
    // MARK: SearchResultsUpdater
    func updateResults(searchResults: SearchResults) -> Void {
        
        self.searchResults = searchResults
        if editionsCount != searchResults.numFound {
            editionsCount = max( searchResults.numFound, fetchedResultsController.count )
        }
        highWaterMark = min( editionsCount, searchResults.start + searchResults.pageSize )

    }
    
    private func updateFooter( text: String = "" ) {
        
        updateTableFooter( tableVC?.tableView, highWaterMark: highWaterMark, numFound: editionsCount, text: text )
    }
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch(controller: FetchedWorkEditionsController) {
        
        if 0 == controller.count {
            
            newQuery( workKey, userInitiated: true, refreshControl: nil )
            
        } else if let detail = objectAtIndexPath( NSIndexPath( forRow: 0, inSection: 0 ) ) {
            
            if detail.isProvisional {
                
                newQuery( workKey, userInitiated: true, refreshControl: nil )
                
            } else {
                
                highWaterMark = controller.count
                if highWaterMark % kPageSize != 0 {
                    editionsCount = highWaterMark
                } else {
                    editionsCount = highWaterMark + kPageSize
                }
                if 0 == searchResults.numFound {
                    searchResults = SearchResults( start: 0, numFound: editionsCount + 1, pageSize: kPageSize )
                }
            }

            updateFooter()
        }
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedWorkEditionsController ) {
//        tableVC?.tableView.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedWorkEditionsController ) {

        if let tableView = tableVC?.tableView {
            
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
    
    func fetchedResultsController( controller: FetchedWorkEditionsController,
        didChangeObject change: FetchedResultsObjectChange< OLEditionDetail > ) {

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
    
    func fetchedResultsController(controller: FetchedWorkEditionsController,
        didChangeSection change: FetchedResultsSectionChange< OLEditionDetail >) {

        switch change {
        case let .Insert(_, index):
            insertedSectionIndexes.addIndex( index )
        case let .Delete(_, index):
            deletedSectionIndexes.addIndex( index )
        }
    }

    // MARK: install query coordinators

    func installEditionCoordinator( editionDetailVC: OLEditionDetailViewController, indexPath: NSIndexPath ) {
        
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
    
    func installEditionDeluxeCoordinator( deluxeDetailVC: OLDeluxeDetailTableViewController, indexPath: NSIndexPath ) {
        
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
