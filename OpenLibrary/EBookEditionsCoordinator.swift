//
//  EBookEditionsCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 7/20/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import SafariServices

import BNRCoreDataStack
import PSOperations

private let kEBookEditionsCache = "eBookEditionsCache"

private let kPageSize = 100
    

class EBookEditionsCoordinator: OLQueryCoordinator, FetchedResultsControllerDelegate {
    
    typealias FetchedEBookItemController = FetchedResultsController< OLEBookItem >
    
    weak var tableVC: UITableViewController?
    
    var workEditionsGetOperation: Operation?
    var ebookItemGetOperation: Operation?
    
    private lazy var fetchedResultsController: FetchedEBookItemController = {
        
        let fetchRequest = NSFetchRequest( entityName: OLEBookItem.entityName )
        
//        let secondsPerDay = NSTimeInterval( 24 * 60 * 60 )
//        let today = NSDate()
//        let lastWeek = today.dateByAddingTimeInterval( -7 * secondsPerDay )
        
        fetchRequest.predicate =
            NSPredicate( format: "workKey==%@", "\(self.workDetail.key)" )
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "publish_date", ascending: false)]
        fetchRequest.fetchBatchSize = 100
        
        let frc = FetchedEBookItemController(
                        fetchRequest: fetchRequest,
                        managedObjectContext: self.coreDataStack.mainQueueContext,
                        sectionNameKeyPath: nil
                    )
        
        frc.setDelegate( self )
        return frc
    }()
    
    var workDetail: OLWorkDetail
    var editionKeys = [String]()
    var editionsCount = 0
    var searchResults = SearchResults()
    
    var highWaterMark = 0
    
    init(
        operationQueue: OperationQueue,
        coreDataStack: CoreDataStack,
        workDetail: OLWorkDetail,
        editionKeys: [String],
        tableVC: UITableViewController
        ) {
        
        self.workDetail = workDetail
        self.editionKeys = editionKeys
        self.tableVC = tableVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: tableVC )
    }
    
    func numberOfSections() -> Int {
        
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func numberOfRowsInSection( section: Int ) -> Int {
        
        return fetchedResultsController.sections?[section].objects.count ?? 0
    }
    
    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLEBookItem? {
        
        guard let sections = fetchedResultsController.sections else {
            assertionFailure("Sections missing")
            return nil
        }
        
        let section = sections[indexPath.section]
        guard indexPath.row < section.objects.count else {
            assertionFailure( "row:\(indexPath.row) out of bounds" )
            return nil
        }
        
        let item = section.objects[indexPath.row]
        
        let editionDetail = item.matchingEdition()
        if editionDetail?.isProvisional ?? true {
            
            if libraryIsReachable( tattle: false ) {
                
                let getOperation =
                    EditionDetailGetOperation(
                            queryText: item.editionKey,
                            parentObjectID: workDetail.objectID,
                            coreDataStack: coreDataStack
                        ) {
                            
                            dispatch_async( dispatch_get_main_queue() ) {
                            
                                item.matchingEdition()
                            }
                        }
                getOperation.userInitiated = false
                operationQueue.addOperation( getOperation )
            }
        }
        
        return item
    }
    
    func didSelectItemAtIndexPath( indexPath: NSIndexPath ) -> Void {
        
        guard let object = objectAtIndexPath( indexPath ) else { return }
        
        switch object.status {
            
            case "full access":
                tableVC?.performSegueWithIdentifier( "EbookEditionTableViewCell", sender: tableVC )
                break
            
            case "lendable":
                if let url = NSURL( string: object.itemURL ) {
                    showLinkedWebSite( tableVC!, url: url )
                }
                break
            
            case "checked out", "restricted":
                break
            
            default:
                print( "unknown eBook status: \(object.status)" )
                break
        }
    }
    
    func displayToCell( cell: EbookEditionTableViewCell, indexPath: NSIndexPath ) -> OLEBookItem? {
        
        guard let result = objectAtIndexPath( indexPath ) else { return nil }
        
        if nil != result.editionDetail {

            cell.configure(
                    tableVC!.tableView,
                    key: result.editionKey,
                    eBookStatusText: result.status,
                    data: result.editionDetail
                )
        
        } else {
            
            newQuery( false, refreshControl: nil )
        }
        
        displayThumbnail( result, cell: cell )
                
        return result
    }
    
    func updateUI() {
        
        do {
            NSFetchedResultsController.deleteCacheWithName( kEBookEditionsCache )
            try fetchedResultsController.performFetch()
        }
        catch {
            print("Error in the fetched results controller: \(error).")
        }
    }
    
    
    func newQuery( userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        guard libraryIsReachable( tattle: false ) else {
            
            return
        }
        
        if nil == ebookItemGetOperation {
            
            updateFooter( "fetching eBook editions..." )
            
            ebookItemGetOperation =
                IAEBookItemListGetOperation(
                    editionKeys: editionKeys,
                    coreDataStack: coreDataStack
                ) {
                    
                    [weak self] in
                    
                    if let strongSelf = self {
                        
                        dispatch_async( dispatch_get_main_queue() ) {
                            
                            strongSelf.refreshComplete( refreshControl )
                            
                            strongSelf.updateFooter()
                            
                            strongSelf.ebookItemGetOperation = nil
                       }
                    }
            }
            operationQueue.addOperation( ebookItemGetOperation! )
        }
    }
    
    func refreshQuery( refreshControl: UIRefreshControl? ) {
        
        newQuery( true, refreshControl: refreshControl )
    }
    
//    private func needAnotherPage( index: Int, highWaterMark: Int ) -> Bool {
//        
//        return
//            nil == workEditionsGetOperation &&
//                !workKey.isEmpty &&
//                highWaterMark < editionsCount &&
//                index >= ( highWaterMark - ( searchResults.pageSize / 4 ) )
//    }
    
    // MARK: SearchResultsUpdater
    func updateResults(searchResults: SearchResults) -> Void {
        
        self.searchResults = searchResults
        self.highWaterMark = min( searchResults.numFound, searchResults.start + searchResults.pageSize )
        if self.editionsCount != searchResults.numFound {
            self.editionsCount = searchResults.numFound
        }

        updateFooter()
    }
    
    private func updateHeader( string: String = "" ) {
        
        updateTableHeader( tableVC?.tableView, text: string )
    }
    
    private func updateFooter( text: String = "" ) -> Void {
        
        highWaterMark = fetchedResultsController.count
        searchResults = SearchResults(start: 0, numFound: highWaterMark, pageSize: kPageSize )
        
        updateTableFooter( tableVC?.tableView, highWaterMark: highWaterMark, numFound: searchResults.numFound, text: text )
    }
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch(controller: FetchedEBookItemController) {
        
        if 0 == controller.count {
            
            newQuery( false, refreshControl: nil )
            
        }
        
        if 0 != controller.count {
            
            updateFooter()
        }
    }

    func fetchedResultsControllerWillChangeContent( controller: FetchedEBookItemController ) {
        tableVC?.tableView.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedEBookItemController ) {
        tableVC?.tableView.endUpdates()
    }
    
    func fetchedResultsController( controller: FetchedEBookItemController,
                                   didChangeObject change: FetchedResultsObjectChange< OLEBookItem > ) {
        switch change {
        case let .Insert(_, indexPath):
            tableVC?.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            break
            
        case let .Delete(_, indexPath):
            tableVC?.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            break
            
        case let .Move(_, fromIndexPath, toIndexPath):
            tableVC?.tableView.moveRowAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
            
        case let .Update(_, indexPath):
            tableVC?.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
    }
    
    func fetchedResultsController(controller: FetchedEBookItemController,
                                  didChangeSection change: FetchedResultsSectionChange< OLEBookItem >) {
        switch change {
        case let .Insert(_, index):
            tableVC?.tableView.insertSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
            
        case let .Delete(_, index):
            tableVC?.tableView.deleteSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
        }
    }
    
    // MARK: install query coordinators
    
    func installBookDownloadCoordinator( destVC: OLBookDownloadViewController ) -> Void {
        
        guard let sourceVC = tableVC else { return }
        
        guard let indexPath = sourceVC.tableView.indexPathForSelectedRow else { return }
        
        guard let object = objectAtIndexPath( indexPath ) else { return }
        
        guard let itemURL = NSURL( string: object.itemURL ) else { assert( false ); return }
        
        guard let title = object.editionDetail?.title else { assert( false ); return }
        
        destVC.queryCoordinator =
            BookDownloadCoordinator(
                operationQueue: operationQueue,
                coreDataStack: coreDataStack,
                heading: title,
                bookURL: itemURL,
                downloadVC: destVC
        )
    }
}

extension EBookEditionsCoordinator: SFSafariViewControllerDelegate {
    
    func showLinkedWebSite( vc: UIViewController, url: NSURL? ) {
        
        if let url = url {
            let webVC = SFSafariViewController( URL: url )
            webVC.delegate = self
            vc.presentViewController( webVC, animated: true, completion: nil )
        }
    }
    
    // MARK: SFSafariViewControllerDelegate
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        
        controller.dismissViewControllerAnimated( true, completion: nil )
    }
    
}
