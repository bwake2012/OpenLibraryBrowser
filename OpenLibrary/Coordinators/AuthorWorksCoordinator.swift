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

private let kWorksByAuthorCache = "worksByAuthor"

private let kPageSize = 100
    
class AuthorWorksCoordinator: OLQueryCoordinator, FetchedResultsControllerDelegate {
    
    typealias FetchedOLWorkDetailController = FetchedResultsController< OLWorkDetail >
    
    let authorWorksTableVC: OLAuthorDetailWorksTableViewController

    var authorWorksGetOperation: Operation?
    
    private lazy var fetchedResultsController: FetchedOLWorkDetailController = {
        
        let fetchRequest = NSFetchRequest( entityName: OLWorkDetail.entityName )
        let key = self.authorKey
        fetchRequest.predicate = NSPredicate( format: "author_key==%@", "\(key)" )
        
        fetchRequest.sortDescriptors =
            [
                NSSortDescriptor(key: "coversFound", ascending: false),
                NSSortDescriptor(key: "index", ascending: true)
            ]
        
        let frc = FetchedOLWorkDetailController( fetchRequest: fetchRequest,
            managedObjectContext: self.coreDataStack.mainQueueContext,
            sectionNameKeyPath: nil )
        
        frc.setDelegate( self )
        return frc
    }()
    
    var authorKey: String
    var authorNames: [String]
    var numFound = Int64( kPageSize * 2 )
    var searchResults = SearchResults()

    var highWaterMark = 0
    
    init( authorKey: String, authorNames: [String], authorWorksTableVC: OLAuthorDetailWorksTableViewController, coreDataStack: CoreDataStack, operationQueue: OperationQueue ) {
        
        self.authorKey = authorKey
        self.authorNames = authorNames

        self.authorWorksTableVC = authorWorksTableVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
        
        updateUI()
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
        if indexPath.row >= section.objects.count {
            return nil
        } else {
            
            return section.objects[indexPath.row]
        }
    }
    
    func displayToCell( cell: AuthorWorksTableViewCell, indexPath: NSIndexPath ) -> OLWorkDetail? {
        
        if needAnotherPage( indexPath.row ) {
            
            nextQueryPage( highWaterMark )
        }
        
        guard let workDetail = objectAtIndexPath( indexPath ) else { return nil }
        
        cell.configure( workDetail )
        
//        print( "work: \(result.title) has covers: \(!result.covers.isEmpty)" )
        
        if workDetail.hasImage {
                
            let localURL = workDetail.localURL( "S" )
            if !cell.displayImage( localURL ) {
            
                let url = localURL
                let workCoverGetOperation =
                    ImageGetOperation( numberID: workDetail.firstImageID, imageKeyName: "id", localURL: url, size: "S", type: "b" )
                        {
                        
                        dispatch_async( dispatch_get_main_queue() ) {
                            
                            cell.displayImage( url )
                        }
                }
                
                workCoverGetOperation.userInitiated = true
                operationQueue.addOperation( workCoverGetOperation )
            }
        }
        
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
                                strongSelf.updateUI()
                            }
                            strongSelf.authorWorksGetOperation = nil
                        }
                    }
            
            authorWorksGetOperation!.userInitiated = userInitiated
            operationQueue.addOperation( authorWorksGetOperation! )
        }
    }
    
    func nextQueryPage( offset: Int ) -> Void {
        
        if nil == authorWorksGetOperation && !authorKey.isEmpty {
            
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
                    strongSelf.authorWorksGetOperation = nil
                }
            }
            
            authorWorksGetOperation!.userInitiated = false
            operationQueue.addOperation( authorWorksGetOperation! )
        }
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
                if strongSelf.numFound != Int64( searchResults.numFound ) {
                    strongSelf.numFound = Int64( searchResults.numFound )
                }
            }
        }
    }
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch( controller: FetchedOLWorkDetailController ) {
        
        if 0 == controller.count {
            
            newQuery( authorKey, userInitiated: true, refreshControl: nil )

        } else {
            
            highWaterMark = controller.count
        }
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedOLWorkDetailController ) {
        authorWorksTableVC.tableView.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedOLWorkDetailController ) {
        authorWorksTableVC.tableView.endUpdates()
    }
    
    func fetchedResultsController( controller: FetchedOLWorkDetailController,
        didChangeObject change: FetchedResultsObjectChange< OLWorkDetail > ) {
            switch change {
            case let .Insert(_, indexPath):
                authorWorksTableVC.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                break
                
            case let .Delete(_, indexPath):
                authorWorksTableVC.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                break
                
            case let .Move(_, fromIndexPath, toIndexPath):
                authorWorksTableVC.tableView.moveRowAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
                
            case let .Update(_, indexPath):
                authorWorksTableVC.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
    }
    
    func fetchedResultsController(controller: FetchedOLWorkDetailController,
        didChangeSection change: FetchedResultsSectionChange< OLWorkDetail >) {
            switch change {
            case let .Insert(_, index):
                authorWorksTableVC.tableView.insertSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
                
            case let .Delete(_, index):
                authorWorksTableVC.tableView.deleteSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
            }
    }
    
    // MARK: install Query Coordinators
    
    func installWorkDetailCoordinator( destVC: OLWorkDetailViewController, indexPath: NSIndexPath ){
    
        guard let workDetail = objectAtIndexPath( indexPath ) else {
            
            fatalError( "work detail not found at: \(indexPath)" )
        }

        destVC.queryCoordinator =
            WorkDetailCoordinator(
                    authorNames: authorNames,
                    operationQueue: self.operationQueue,
                    coreDataStack: self.coreDataStack,
                    searchInfo: workDetail,
                    workDetailVC: destVC
                )

    }
}
