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

//import BNRCoreDataStack
import PSOperations

// private let kEBookEditionsCache = "eBookEditionsCache"

private let kPageSize = 100
    

class EBookEditionsCoordinator: OLQueryCoordinator {
    
    typealias FetchedEBookItemController = NSFetchedResultsController< OLEBookItem >
    
    weak var tableVC: OLEBookEditionsTableViewController?
    
    var workEditionsGetOperation: PSOperation?
    var ebookItemGetOperation: PSOperation?
    
    fileprivate var cachedFetchedResultsController: FetchedEBookItemController?
    
    fileprivate var fetchedResultsController: FetchedEBookItemController {
        
        guard let frc = cachedFetchedResultsController else {
            
            let frc = buildFetchedResultsController()
            
            cachedFetchedResultsController = frc
            return frc
        }
        
        return frc
    }
    
    var workDetail: OLWorkDetail
    var editionKeys = [String]()
    var editionsCount = 0
    var searchResults = SearchResults()
    
    var highWaterMark = 0
    
    init(
        operationQueue: PSOperationQueue,
        dataStack: OLDataStack,
        workDetail: OLWorkDetail,
        editionKeys: [String],
        tableVC: OLEBookEditionsTableViewController
        ) {
        
        self.workDetail = workDetail
        self.editionKeys = editionKeys
        self.tableVC = tableVC
        
        super.init( operationQueue: operationQueue, dataStack: dataStack, viewController: tableVC )
    }
    
    func numberOfSections() -> Int {
        
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func numberOfRowsInSection( _ section: Int ) -> Int {
        
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func objectAtIndexPath( _ indexPath: IndexPath ) -> OLEBookItem? {
        
        guard let sections = fetchedResultsController.sections else {
            assertionFailure("Sections missing")
            return nil
        }
        
        let section = sections[indexPath.section]
        guard let itemsInSection = section.objects as? [OLEBookItem] else {
            fatalError("Missing items")
        }
        guard indexPath.row < itemsInSection.count else {
            assertionFailure( "row:\((indexPath as NSIndexPath).row) out of bounds" )
            return nil
        }
        
        let item = itemsInSection[indexPath.row]
        
        let editionDetail = item.matchingEdition()
        if editionDetail?.isProvisional ?? true {
            
            if libraryIsReachable( tattle: false ) {
                
                let currentObjectID = editionDetail?.objectID
                
                let getOperation =
                    EditionDetailGetOperation(
                            queryText: item.editionKey,
                            parentObjectID: workDetail.objectID,
                            currentObjectID: currentObjectID,
                            dataStack: dataStack
                        ) {
                            
                            DispatchQueue.main.async {
                            
                                item.matchingEdition()
                            }
                        }
                getOperation.userInitiated = false
                operationQueue.addOperation( getOperation )
            }
        }
        
        return item
    }
    
    func didSelectItemAtIndexPath( _ indexPath: IndexPath ) -> Void {
        
        guard let object = objectAtIndexPath( indexPath ) else { return }
        
        switch object.status {
            
            case "full access":
                tableVC?.performSegue( withIdentifier: "EbookEditionTableViewCell", sender: tableVC )
                break
            
            case "lendable":
                if let url = URL( string: object.itemURL ) {
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
    
    @discardableResult func displayToCell( _ cell: EbookEditionTableViewCell, indexPath: IndexPath ) -> OLEBookItem? {
        
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
//            NSFetchedResultsController< OLEBookItem >.deleteCache( withName: kEBookEditionsCache )
            try fetchedResultsController.performFetch()

            controllerDidPerformFetch( fetchedResultsController )
        }
        catch {
            print("Error in the fetched results controller: \(error).")
        }
    }
    
    
    func newQuery( _ userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        guard libraryIsReachable( tattle: false ) else {
            
            return
        }
        
        if nil == ebookItemGetOperation {
            
            updateFooter( "fetching eBook editions..." )
            
            ebookItemGetOperation =
                IAEBookItemListGetOperation(
                    editionKeys: editionKeys,
                    dataStack: dataStack
                ) {
                    
                    [weak self] in
                    
                    DispatchQueue.main.async {
                            
                        if let strongSelf = self {
                        
                            strongSelf.refreshComplete( refreshControl )
                            
                            strongSelf.updateFooter()
                            
                            strongSelf.ebookItemGetOperation = nil
                       }
                    }
            }
            operationQueue.addOperation( ebookItemGetOperation! )
        }
    }
    
    func refreshQuery( _ refreshControl: UIRefreshControl? ) {
        
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
    func updateResults(_ searchResults: SearchResults) -> Void {
        
        self.searchResults = searchResults
        self.highWaterMark = min( searchResults.numFound, searchResults.start + searchResults.pageSize )
        if self.editionsCount != searchResults.numFound {
            self.editionsCount = searchResults.numFound
        }

        updateFooter()
    }
    
    fileprivate func updateHeader( _ string: String = "" ) {
        
        updateTableHeader( tableVC?.tableView, text: string )
    }
    
    fileprivate func updateFooter( _ text: String = "" ) -> Void {
        
        highWaterMark = numberOfRowsInSection( 0 )
        searchResults = SearchResults(start: 0, numFound: highWaterMark, pageSize: kPageSize )
        
        updateTableFooter( tableVC?.tableView, highWaterMark: highWaterMark, numFound: searchResults.numFound, text: text )
    }

    // MARK: install query coordinators
    
    func installBookDownloadCoordinator( _ destVC: OLBookDownloadViewController ) -> Void {
        
        guard let sourceVC = tableVC else { return }
        
        guard let indexPath = sourceVC.tableView.indexPathForSelectedRow else { return }
        
        guard let object = objectAtIndexPath( indexPath ) else { return }
        
        guard let itemURL = URL( string: object.itemURL ) else { assert( false ); return }
        
        guard let title = object.editionDetail?.title else { assert( false ); return }
        
        destVC.queryCoordinator =
            BookDownloadCoordinator(
                operationQueue: operationQueue,
                dataStack: dataStack,
                heading: title,
                bookURL: itemURL,
                downloadVC: destVC
        )
    }
}

extension EBookEditionsCoordinator: SFSafariViewControllerDelegate {
    
    func showLinkedWebSite( _ vc: UIViewController, url: URL? ) {
        
        if let url = url {
            let webVC = SFSafariViewController( url: url )
            webVC.delegate = self
            vc.present( webVC, animated: true, completion: nil )
        }
    }
    
    // MARK: SFSafariViewControllerDelegate
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        
        controller.dismiss( animated: true, completion: nil )
    }
    
}

extension EBookEditionsCoordinator: NSFetchedResultsControllerDelegate {
    
    func buildFetchedResultsController() -> FetchedEBookItemController {
        
        let fetchRequest = OLEBookItem.buildFetchRequest()
        
        //        let secondsPerDay = NSTimeInterval( 24 * 60 * 60 )
        //        let today = NSDate()
        //        let lastWeek = today.dateByAddingTimeInterval( -7 * secondsPerDay )
        
        let key = self.workDetail.key
        fetchRequest.predicate = NSPredicate( format: "workKey==%@", key )
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "publish_date", ascending: false)]
        fetchRequest.fetchBatchSize = 100
        
        let frc = FetchedEBookItemController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.dataStack.mainQueueContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        frc.delegate = self
        return frc
    }

    
    // MARK: FetchedResultsControllerDelegate
    func controllerDidPerformFetch(_ controller: FetchedEBookItemController) {
        
        guard nil != controller.fetchedObjects?.first else {
            
            newQuery( false, refreshControl: nil )
            return
        }
        
        highWaterMark = numberOfRowsInSection( 0 )
        updateFooter()
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
    }
    
    func controllerDidChangeContent( _ controller: NSFetchedResultsController<NSFetchRequestResult> ) {
        
        if let tableView = tableVC?.tableView {
            
            // NSLog( "fetchedResultsControllerDidChangeContent start" )
            
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
            
            // NSLog( "fetchedResultsControllerDidChangeContent end" )
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
            fatalError("Unexpected NSFetchedResultsChangeType)")
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

