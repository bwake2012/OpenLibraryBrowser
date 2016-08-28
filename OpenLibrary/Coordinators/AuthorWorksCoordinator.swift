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
    
class AuthorWorksCoordinator: OLQueryCoordinator, FetchedResultsControllerDelegate {
    
    typealias FetchedOLWorkDetailController = FetchedResultsController< OLWorkDetail >
    
    weak var authorWorksTableVC: OLAuthorDetailWorksTableViewController?

    var authorWorksGetOperation: Operation?
    
    private lazy var fetchedResultsController: FetchedOLWorkDetailController = {
        
        let fetchRequest = NSFetchRequest( entityName: OLWorkDetail.entityName )
        let key = self.authorKey

        let secondsPerDay = NSTimeInterval( 24 * 60 * 60 )
        let today = NSDate()
        let lastWeek = today.dateByAddingTimeInterval( -7 * secondsPerDay )
        
        fetchRequest.predicate = NSPredicate( format: "author_key==%@ && retrieval_date > %@", "\(key)", lastWeek )
        
        fetchRequest.sortDescriptors =
            [
                NSSortDescriptor(key: "coversFound", ascending: false),
                NSSortDescriptor(key: "index", ascending: true)
            ]
        fetchRequest.fetchBatchSize = 100
        
        let frc = FetchedOLWorkDetailController( fetchRequest: fetchRequest,
            managedObjectContext: self.coreDataStack.mainQueueContext,
            sectionNameKeyPath: nil )
        
        frc.setDelegate( self )
        return frc
    }()
    
    var authorKey: String
    var numFound = kPageSize * 2
    var searchResults = SearchResults()

    var highWaterMark = 0
    
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
        
        if needAnotherPage( indexPath.row ) {
            
            nextQueryPage( highWaterMark )
        }
        
        let section = sections[indexPath.section]
        if indexPath.row >= section.objects.count {
            return nil
        } else {
            
            return section.objects[indexPath.row]
        }
    }
    
    func displayToCell( cell: AuthorWorksTableViewCell, indexPath: NSIndexPath ) -> OLWorkDetail? {
        
        guard let workDetail = objectAtIndexPath( indexPath ) else { return nil }
        
        cell.configure( authorWorksTableVC!.tableView, key: workDetail.key, data: workDetail )
        
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

        if nil == authorWorksGetOperation {
            self.searchResults = SearchResults()
            self.highWaterMark = 0
            
            updateFooter( "fetching author works..." )
            
            authorWorksGetOperation =
                AuthorWorksGetOperation(
                        queryText: authorKey,
                        offset: 0, limit: kPageSize,
                        coreDataStack: coreDataStack,
                        updateResults: self.updateResults
                    ) {
                        [weak self] in
                        
                        if let strongSelf = self {

                            dispatch_async( dispatch_get_main_queue() ) {

                                refreshControl?.endRefreshing()
//                                strongSelf.updateUI()
                            }
                            
                            strongSelf.refreshComplete( refreshControl )
                            
                            strongSelf.updateFooter()

                            strongSelf.authorWorksGetOperation = nil
                        }
                    }
            
            authorWorksGetOperation!.userInitiated = userInitiated
            operationQueue.addOperation( authorWorksGetOperation! )
        }
    }
    
    func nextQueryPage( offset: Int ) -> Void {
        
        if nil == authorWorksGetOperation && !authorKey.isEmpty {
            
            updateFooter( "fetching more author works..." )
            
            authorWorksGetOperation =
                AuthorWorksGetOperation(
                        queryText: self.authorKey,
                        offset: offset, limit: kPageSize,
                        coreDataStack: coreDataStack,
                        updateResults: self.updateResults
                    ) {
                [weak self] in
                        
                if let strongSelf = self {
                    dispatch_async( dispatch_get_main_queue() ) {
        //                refreshControl?.endRefreshing()
    //                    self.updateUI()
                    }
                    
                    strongSelf.updateFooter()
                    strongSelf.authorWorksGetOperation = nil
                }
            }
            
            authorWorksGetOperation!.userInitiated = false
            operationQueue.addOperation( authorWorksGetOperation! )
        }
    }
    
    func refreshQuery( refreshControl: UIRefreshControl? ) {
        
        newQuery( authorKey, userInitiated: true, refreshControl: refreshControl )
    }
    
    private func needAnotherPage( index: Int ) -> Bool {
        
        return
            nil == authorWorksGetOperation &&
            !self.authorKey.isEmpty &&
            highWaterMark < Int( self.numFound ) &&
            index >= ( highWaterMark - 1 )
    }
    
    // MARK: SearchResultsUpdater
    func updateResults(searchResults: SearchResults) -> Void {
        
        dispatch_async( dispatch_get_main_queue() ) {
            [weak self] in
            
            if let strongSelf = self {
                strongSelf.searchResults = searchResults
                strongSelf.highWaterMark = searchResults.start + searchResults.pageSize
                if strongSelf.numFound != searchResults.numFound {
                    strongSelf.numFound = searchResults.numFound
                }
                
            }
        }
    }
    
    func updateFooter( text: String = "" ) {
        
        updateTableFooter( authorWorksTableVC?.tableView, highWaterMark: highWaterMark, numFound: Int( numFound ), text: text )
    }
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch( controller: FetchedOLWorkDetailController ) {
        
        if 0 == controller.count {
            
            newQuery( authorKey, userInitiated: true, refreshControl: nil )
            
        } else if let detail = objectAtIndexPath( NSIndexPath( forRow: 0, inSection: 0 ) ) {
            
            if detail.isProvisional {
                
                newQuery( authorKey, userInitiated: true, refreshControl: nil )

            } else {
                
                highWaterMark = controller.count
                if highWaterMark % kPageSize != 0 {
                    numFound = highWaterMark
                } else {
                    numFound = highWaterMark + kPageSize
                }
                
                updateFooter()
            }
        }
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
    
    // MARK: install Query Coordinators
    
    func installWorkDetailCoordinator( destVC: OLWorkDetailViewController, indexPath: NSIndexPath ){
    
        guard let workDetail = objectAtIndexPath( indexPath ) else {
            
            fatalError( "work detail not found at: \(indexPath)" )
        }

        destVC.queryCoordinator =
            WorkDetailCoordinator(
                    operationQueue: self.operationQueue,
                    coreDataStack: self.coreDataStack,
                    searchInfo: workDetail,
                    workDetailVC: destVC
                )

    }
}
