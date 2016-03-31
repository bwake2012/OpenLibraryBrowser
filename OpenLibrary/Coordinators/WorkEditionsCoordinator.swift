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
    
class WorkEditionsCoordinator: NSObject, FetchedResultsControllerDelegate {
    
    typealias FetchedWorkEditionsController = FetchedResultsController< OLEditionDetail >
    
    let tableView: UITableView?

    var operationQueue: OperationQueue
    var authorEditionsGetOperation: Operation?
    
    let coreDataStack: CoreDataStack
    private lazy var fetchedResultsController: FetchedWorkEditionsController = {
        
        let fetchRequest = NSFetchRequest( entityName: OLEditionDetail.entityName )
        fetchRequest.predicate = NSPredicate( format: "author_key==%@", "\(self.authorKey)" )
        
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
    
    var authorKey = ""
    var editionsCount = Int( 0 )
    var searchResults = SearchResults()
    
    var highWaterMark = 0
    
    init?( searchInfo: OLWorkDetail.SearchInfo, withCoversOnly: Bool, tableView: UITableView, coreDataStack: CoreDataStack, operationQueue: OperationQueue ) {
        
        self.authorKey = searchInfo.key
        self.withCoversOnly = withCoversOnly
//        self.worksCount = searchInfo.work_count
        self.tableView = tableView
        self.operationQueue = operationQueue
        self.coreDataStack = coreDataStack
        
        super.init()
        
        updateUI()
    }
    
    func numberOfSections() -> Int {
        
        return fetchedResultsController.sections?.count ?? 1
    }

    func numberOfRowsInSection( section: Int ) -> Int {

        return fetchedResultsController.sections?[section].objects.count ?? 0
    }
    
    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLEditionDetail? {
        
        if needAnotherPage( indexPath.row, highWaterMark: highWaterMark ) {
            
            nextQueryPage( highWaterMark )
        }
        
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
    
    func updateUI() {

        do {
            NSFetchedResultsController.deleteCacheWithName( kWorkEditonsCache )
            try fetchedResultsController.performFetch()
        }
        catch {
            print("Error in the fetched results controller: \(error).")
        }
        
        tableView!.reloadData()
    }

    func newQuery( authorKey: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) {

        self.searchResults = SearchResults()
        self.authorKey = authorKey
        self.highWaterMark = 0
        
        authorEditionsGetOperation =
            WorkEditionsGetOperation(
                    queryText: authorKey,
                    offset: 0,
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
                        
                        strongSelf.authorEditionsGetOperation = nil
                    }
                }
        
        authorEditionsGetOperation!.userInitiated = userInitiated
        operationQueue.addOperation( authorEditionsGetOperation! )
    }
    
    func nextQueryPage( offset: Int ) -> Void {
        
        if 0 == operationQueue.operationCount && !authorKey.isEmpty {
            
            authorEditionsGetOperation =
                WorkEditionsGetOperation(
                        queryText: self.authorKey,
                        offset: offset,
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
                            
                            strongSelf.authorEditionsGetOperation = nil
                        }
            }
            
            authorEditionsGetOperation!.userInitiated = false
            operationQueue.addOperation( authorEditionsGetOperation! )
        }
    }
    
    private func needAnotherPage( index: Int, highWaterMark: Int ) -> Bool {
        
        return
            nil == authorEditionsGetOperation &&
            !authorKey.isEmpty &&
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
        
        tableView?.reloadData()
        
        if 0 == controller.count {
            
            newQuery( authorKey, userInitiated: true, refreshControl: nil )
        }
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedWorkEditionsController ) {
        tableView?.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedWorkEditionsController ) {
        tableView?.endUpdates()
    }
    
    func fetchedResultsController( controller: FetchedWorkEditionsController,
        didChangeObject change: FetchedResultsObjectChange< OLEditionDetail > ) {
            switch change {
            case let .Insert(_, indexPath):
                tableView?.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                break
                
            case let .Delete(_, indexPath):
                tableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                break
                
            case let .Move(_, fromIndexPath, toIndexPath):
                tableView?.moveRowAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
                
            case let .Update(_, indexPath):
                tableView?.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
    }
    
    func fetchedResultsController(controller: FetchedWorkEditionsController,
        didChangeSection change: FetchedResultsSectionChange< OLEditionDetail >) {
            switch change {
            case let .Insert(_, index):
                tableView?.insertSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
                
            case let .Delete(_, index):
                tableView?.deleteSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
            }
    }
}
