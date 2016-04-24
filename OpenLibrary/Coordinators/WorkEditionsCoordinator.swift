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

private let kWorkEditonsCache = "workEditionsCache"

private let kPageSize = 100

class WorkEditionsCoordinator: OLQueryCoordinator, FetchedResultsControllerDelegate {
    
    typealias FetchedWorkEditionsController = FetchedResultsController< OLEditionDetail >
    
    let tableVC: UITableViewController

    var workEditionsGetOperation: Operation?
    
    private lazy var fetchedResultsController: FetchedWorkEditionsController = {
        
        let fetchRequest = NSFetchRequest( entityName: OLEditionDetail.entityName )
        fetchRequest.predicate = NSPredicate( format: "work_key==%@", "\(self.workKey)" )
        
        fetchRequest.sortDescriptors =
            [NSSortDescriptor(key: "coversFound", ascending: false),
             NSSortDescriptor(key: "index", ascending: true)]
        
        let frc = FetchedWorkEditionsController( fetchRequest: fetchRequest,
            managedObjectContext: self.coreDataStack.mainQueueContext,
            sectionNameKeyPath: nil )
        
        frc.setDelegate( self )
        return frc
    }()
    
    let withCoversOnly: Bool
    
    var workKey = ""
    var editionsCount = Int( 0 )
    var searchResults = SearchResults()
    
    var highWaterMark = 0
    
    init( workKey: String, withCoversOnly: Bool, tableVC: UITableViewController, coreDataStack: CoreDataStack, operationQueue: OperationQueue ) {
        
        self.workKey = workKey
        self.withCoversOnly = withCoversOnly
//        self.worksCount = searchInfo.work_count
        self.tableVC = tableVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
        
        updateUI()
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
        if indexPath.row >= section.objects.count {
            return nil
        } else {
            
            return section.objects[indexPath.row]
        }
    }
    
    func displayToCell( cell: WorkEditionTableViewCell, indexPath: NSIndexPath ) -> OLEditionDetail? {
        
        if needAnotherPage( indexPath.row, highWaterMark: highWaterMark ) {
            
            nextQueryPage( highWaterMark )
        }
        
        guard let result = objectAtIndexPath( indexPath ) else { return nil }
        
        cell.configure( result )
        
        if result.hasImage {
                
            let localURL = result.localURL( result.key, size: "S" )
            if !cell.displayImage( localURL ) {
            
                let url = localURL
                let editionCoverGetOperation =
                    ImageGetOperation( numberID: result.covers[0], imageKeyName: "id", localURL: url, size: "S", type: "b" )
                    {
                        dispatch_async( dispatch_get_main_queue() ) {
                            
                            cell.displayImage( url )
                        }
                }
                
                editionCoverGetOperation.userInitiated = true
                operationQueue.addOperation( editionCoverGetOperation )
            }
        }
        
        return result
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

        if nil == workEditionsGetOperation {
            self.searchResults = SearchResults()
            self.workKey = workKey
            self.highWaterMark = 0
            
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
                                    strongSelf.updateUI()
                                }
                            
                            strongSelf.workEditionsGetOperation = nil
                        }
                    }
            
            workEditionsGetOperation!.userInitiated = userInitiated
            operationQueue.addOperation( workEditionsGetOperation! )
        }
    }
    
    func nextQueryPage( offset: Int ) -> Void {
        
        if nil == workEditionsGetOperation && !workKey.isEmpty {
            
            workEditionsGetOperation =
                WorkEditionsGetOperation(
                        queryText: self.workKey,
                        offset: offset, limit: kPageSize,
                        withCoversOnly: withCoversOnly,
                        coreDataStack: coreDataStack,
                        updateResults: self.updateResults
                    ) {
                
                        [weak self] in
                        if let strongSelf = self {
                            dispatch_async( dispatch_get_main_queue() ) {
                                
//                                refreshControl?.endRefreshing()
//                                strongSelf.updateUI()
                            }
                            
                            strongSelf.workEditionsGetOperation = nil
                        }
                    }
            
            workEditionsGetOperation!.userInitiated = false
            operationQueue.addOperation( workEditionsGetOperation! )
        }
    }
    
    private func needAnotherPage( index: Int, highWaterMark: Int ) -> Bool {
        
        return
            nil == workEditionsGetOperation &&
            !workKey.isEmpty &&
            highWaterMark < editionsCount &&
            index >= ( highWaterMark - ( searchResults.pageSize / 4 ) )
    }
    
    // MARK: SearchResultsUpdater
    func updateResults(searchResults: SearchResults) -> Void {
        
        self.searchResults = searchResults
        self.highWaterMark = searchResults.start + searchResults.pageSize
        if self.editionsCount != searchResults.numFound {
            self.editionsCount = searchResults.numFound
        }
    }
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch(controller: FetchedWorkEditionsController) {
        
        if 0 == controller.count {
            
            newQuery( workKey, userInitiated: true, refreshControl: nil )

        } else {
            
            highWaterMark = controller.count
        }
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedWorkEditionsController ) {
        tableVC.tableView.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedWorkEditionsController ) {
        tableVC.tableView.endUpdates()
    }
    
    func fetchedResultsController( controller: FetchedWorkEditionsController,
        didChangeObject change: FetchedResultsObjectChange< OLEditionDetail > ) {
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
    
    func fetchedResultsController(controller: FetchedWorkEditionsController,
        didChangeSection change: FetchedResultsSectionChange< OLEditionDetail >) {
            switch change {
            case let .Insert(_, index):
                tableVC.tableView.insertSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
                
            case let .Delete(_, index):
                tableVC.tableView.deleteSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
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
}
