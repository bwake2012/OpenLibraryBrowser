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

//import BNRCoreDataStack
import PSOperations

private let kAuthorsCache = "authorsOfWork"


class AuthorsCoordinator: OLQueryCoordinator {

    typealias FetchedOLAuthorDetailController = NSFetchedResultsController< OLAuthorDetail >
    
    weak var authorsTableVC: OLAuthorsTableViewController?
    
    lazy var fetchedResultsController: FetchedOLAuthorDetailController = self.BuildFetchedResultsController()
    
    var authorKeys: [String]
    
    var highWaterMark: Int = 0
    var authorDetailsSet: Set< String > = []
    
    init( keys: [String], viewController: OLAuthorsTableViewController, operationQueue: PSOperationQueue, dataStack: OLDataStack ) {
        
        authorsTableVC = viewController
        authorKeys = keys

        super.init( operationQueue: operationQueue, dataStack: dataStack, viewController: viewController )
    }
    
    func updateUI() {
        
        if !authorKeys.isEmpty {
            
            do {
//                NSFetchedResultsController< OLAuthorDetail >.deleteCache( withName: kAuthorsCache )
                try fetchedResultsController.performFetch()

                controllerDidPerformFetch( fetchedResultsController )
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
        
        return fetchedResultsController.sections?[section].objects?.count ?? 0
    }
    
    func objectAtIndexPath( _ indexPath: IndexPath ) -> OLAuthorDetail? {
        
        guard let sections = fetchedResultsController.sections else {
            assertionFailure("Sections missing")
            return nil
        }
        
        let section = sections[indexPath.section]
        
        guard indexPath.row < section.objects?.count ?? 0 else {
            
            return nil
        }
        
        let index = (indexPath as NSIndexPath).row
        guard let authorDetail = section.objects?[index] as? OLAuthorDetail else {
            
            return nil
        }
        
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
                    dataStack: dataStack
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
        
        highWaterMark = numberOfRowsInSection( 0 )

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
        
        let frc =
            FetchedOLAuthorDetailController(
                fetchRequest: fetchRequest,
                managedObjectContext: self.dataStack.mainQueueContext,
                sectionNameKeyPath: nil,
                cacheName: nil // kAuthorDetailCache
        )
        
        frc.delegate = self
        return frc
    }
    
    // MARK: install Query Coordinators
    
}

extension AuthorsCoordinator: NSFetchedResultsControllerDelegate {
    
    // MARK: FetchedResultsControllerDelegate
    func controllerDidPerformFetch( _ controller: FetchedOLAuthorDetailController ) {
        
        highWaterMark = numberOfRowsInSection( 0 )
        updateFooter()
    }
        
    func controllerDidChangeContent( _ controller: NSFetchedResultsController<NSFetchRequestResult> ) {
        
        if let tableView = authorsTableVC?.tableView {
            
            tableView.beginUpdates()
            
            tableView.deleteSections( deletedSectionIndexes as IndexSet, with: .automatic )
            tableView.insertSections( insertedSectionIndexes as IndexSet, with: .automatic )
            
            tableView.deleteRows( at: deletedRowIndexPaths as [IndexPath], with: .automatic )
            tableView.insertRows( at: insertedRowIndexPaths as [IndexPath], with: .automatic )
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
            break
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


