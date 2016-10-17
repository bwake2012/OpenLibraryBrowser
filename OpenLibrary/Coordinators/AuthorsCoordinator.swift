//
//  AuthorsCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 10/14/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import UIKit
import CoreData

import BNRCoreDataStack
import PSOperations

private let kAuthorsCache = "authorsOfWork"


class AuthorsCoordinator: OLQueryCoordinator {

    typealias FetchedOLAuthorDetailController = FetchedResultsController< OLAuthorDetail >
    
    weak var authorsTableVC: OLAuthorsTableViewController?
    
    lazy var fetchedResultsController: FetchedOLAuthorDetailController = self.BuildFetchedResultsController()
    
    var authorKeys: [String]
    
    var highWaterMark: Int = 0
    var authorDetailsSet: Set< String > = []
    
    init( keys: [String], viewController: OLAuthorsTableViewController, operationQueue: OperationQueue, coreDataStack: CoreDataStack ) {
        
        authorsTableVC = viewController
        authorKeys = keys

        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: viewController )
    }
    
    func updateUI() {
        
        if !authorKeys.isEmpty {
            
            do {
                NSFetchedResultsController.deleteCacheWithName( kAuthorsCache )
                try fetchedResultsController.performFetch()
            }
            catch {
                print("Error in the authors fetched results controller: \(error).")
            }
        }
    }
    
    func numberOfSections() -> Int {
        
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func numberOfRowsInSection( section: Int ) -> Int {
        
        return fetchedResultsController.sections?[section].objects.count ?? 0
    }
    
    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLAuthorDetail? {
        
        guard let sections = fetchedResultsController.sections else {
            assertionFailure("Sections missing")
            return nil
        }
        
        let section = sections[indexPath.section]
        
        guard indexPath.row < section.objects.count else {
            
            return nil
        }
        
        let index = indexPath.row
        let authorDetail = section.objects[index]
        
        if authorDetail.isProvisional && !authorDetailsSet.contains( authorDetail.key ) {
            
            newQuery( authorDetail.key, userInitiated: false, refreshControl: nil )
        }
        
        return authorDetail
    }
    
    func displayToCell( cell: AuthorsTableViewCell, indexPath: NSIndexPath ) -> OLAuthorDetail? {
        
        guard let authorDetail = objectAtIndexPath( indexPath ) else { return nil }
        
        cell.configure( authorsTableVC!.tableView, indexPath: indexPath, key: authorDetail.key, data: authorDetail )
        
        //        print( "work: \(result.title) has covers: \(!result.covers.isEmpty)" )
        
        displayThumbnail( authorDetail, cell: cell )
        
        return authorDetail
    }
        
    func newQuery( key: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        authorDetailsSet.insert( key )
        
        authorsTableVC?.coordinatorIsBusy()
        
        let authorDetailGetOperation =
            AuthorDetailGetOperation(
                    queryText: key,
                    parentObjectID: nil,
                    coreDataStack: coreDataStack
                ) {
                    
                    [weak self] in
                    
                    dispatch_async( dispatch_get_main_queue() ) {
                        
                        if let strongSelf = self {
                            
                            refreshControl?.endRefreshing()
                            
                            strongSelf.authorsTableVC?.coordinatorIsNoLongerBusy()
                            
                            strongSelf.updateFooter()
                        }
                    }
                }
        
        authorDetailGetOperation.userInitiated = false
        operationQueue.addOperation( authorDetailGetOperation )
        
    }

    // MARK: Utility
    private func updateFooter( text: String = "" ) -> Void {
        
        highWaterMark = fetchedResultsController.count

        updateTableFooter( authorsTableVC?.tableView, highWaterMark: highWaterMark, numFound: authorKeys.count, text: text )
    }
    
    
    func BuildFetchedResultsController() -> FetchedOLAuthorDetailController {
        
        let fetchRequest = NSFetchRequest( entityName: OLAuthorDetail.entityName )
        let keys = authorKeys
        
//        let secondsPerDay = NSTimeInterval( 24 * 60 * 60 )
//        let today = NSDate()
//        let lastWeek = today.dateByAddingTimeInterval( -7 * secondsPerDay )
        
        fetchRequest.predicate = NSPredicate( format: "key in %@", keys )
        
        fetchRequest.sortDescriptors =
            [
                // NSSortDescriptor(key: "coversFound", ascending: false),
                NSSortDescriptor(key: "name", ascending: true)
            ]
        fetchRequest.fetchBatchSize = 100
        
        let frc = FetchedOLAuthorDetailController( fetchRequest: fetchRequest,
                                                   managedObjectContext: self.coreDataStack.mainQueueContext,
                                                   sectionNameKeyPath: nil )
        
        frc.setDelegate( self )
        return frc
    }
    
    // MARK: install Query Coordinators
    
}

extension AuthorsCoordinator: FetchedResultsControllerDelegate {
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch( controller: FetchedOLAuthorDetailController ) {
        
        highWaterMark = controller.count
        updateFooter()
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedOLAuthorDetailController ) {
        //        authorWorksTableVC?.tableView.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedOLAuthorDetailController ) {
        
        if let tableView = authorsTableVC?.tableView {
            
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
    
    func fetchedResultsController( controller: FetchedOLAuthorDetailController,
                                   didChangeObject change: FetchedResultsObjectChange< OLAuthorDetail > ) {
        
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
    
    func fetchedResultsController(controller: FetchedOLAuthorDetailController,
                                  didChangeSection change: FetchedResultsSectionChange< OLAuthorDetail >) {
        
        switch change {
        case let .Insert(_, index):
            insertedSectionIndexes.addIndex( index )
        case let .Delete(_, index):
            deletedSectionIndexes.addIndex( index )
        }
    }
}


