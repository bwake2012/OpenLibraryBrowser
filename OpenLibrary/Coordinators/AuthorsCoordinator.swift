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
    
    init( keys: [String], viewController: OLAuthorsTableViewController, operationQueue: PSOperationQueue, coreDataStack: OLDataStack ) {
        
        authorsTableVC = viewController
        authorKeys = keys

        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: viewController )
    }
    
    func updateUI() {
        
        if !authorKeys.isEmpty {
            
            do {
//                NSFetchedResultsController< OLAuthorDetail >.deleteCache( withName: kAuthorsCache )
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
    
    func numberOfRowsInSection( _ section: Int ) -> Int {
        
        return fetchedResultsController.sections?[section].objects.count ?? 0
    }
    
    func objectAtIndexPath( _ indexPath: IndexPath ) -> OLAuthorDetail? {
        
        guard let sections = fetchedResultsController.sections else {
            assertionFailure("Sections missing")
            return nil
        }
        
        let section = sections[indexPath.section]
        
        guard indexPath.row < section.objects.count else {
            
            return nil
        }
        
        let index = (indexPath as NSIndexPath).row
        let authorDetail = section.objects[index]
        
        if authorDetail.isProvisional && !authorDetailsSet.contains( authorDetail.key ) {
            
            newQuery( authorDetail.key, userInitiated: false, refreshControl: nil )
        }
        
        return authorDetail
    }
    
    @discardableResult func displayToCell( _ cell: AuthorsTableViewCell, indexPath: IndexPath ) -> OLAuthorDetail? {
        
        guard let authorDetail = objectAtIndexPath( indexPath ) else { return nil }
        
        cell.configure( authorsTableVC!.tableView, indexPath: indexPath, key: authorDetail.key, data: authorDetail )
        
        //        print( "work: \(result.title) has covers: \(!result.covers.isEmpty)" )
        
        displayThumbnail( authorDetail, cell: cell )
        
        return authorDetail
    }
        
    func newQuery( _ key: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        authorDetailsSet.insert( key )
        
        authorsTableVC?.coordinatorIsBusy()
        
        let authorDetailGetOperation =
            AuthorDetailGetOperation(
                    queryText: key,
                    parentObjectID: nil,
                    coreDataStack: coreDataStack
                ) {
                    
                    [weak self] in
                    
                    DispatchQueue.main.async {
                        
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
    fileprivate func updateFooter( _ text: String = "" ) -> Void {
        
        highWaterMark = fetchedResultsController.count

        updateTableFooter( authorsTableVC?.tableView, highWaterMark: highWaterMark, numFound: authorKeys.count, text: text )
    }
    
    
    func BuildFetchedResultsController() -> FetchedOLAuthorDetailController {
        
        let fetchRequest = OLAuthorDetail.buildFetchRequest()
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
    func fetchedResultsControllerDidPerformFetch( _ controller: FetchedOLAuthorDetailController ) {
        
        highWaterMark = controller.count
        updateFooter()
    }
    
    func fetchedResultsControllerWillChangeContent( _ controller: FetchedOLAuthorDetailController ) {
        //        authorWorksTableVC?.tableView.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( _ controller: FetchedOLAuthorDetailController ) {
        
        if let tableView = authorsTableVC?.tableView {
            
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
            
            highWaterMark = max( highWaterMark, controller.count )
            updateFooter()
        }
    }
    
    func fetchedResultsController( _ controller: FetchedOLAuthorDetailController,
                                   didChangeObject change: FetchedResultsObjectChange< OLAuthorDetail > ) {
        
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
    
    func fetchedResultsController(_ controller: FetchedOLAuthorDetailController,
                                  didChangeSection change: FetchedResultsSectionChange< OLAuthorDetail >) {
        
        switch change {
        case let .insert(_, index):
            insertedSectionIndexes.add( index )
        case let .delete(_, index):
            deletedSectionIndexes.add( index )
        }
    }
}


