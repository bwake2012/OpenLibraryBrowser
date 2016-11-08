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
    
    var workEditionsGetOperation: PSOperation?
    var ebookItemGetOperation: PSOperation?
    
    fileprivate lazy var fetchedResultsController: FetchedEBookItemController = {
        
        let fetchRequest = OLEBookItem.buildFetchRequest()
        
//        let secondsPerDay = NSTimeInterval( 24 * 60 * 60 )
//        let today = NSDate()
//        let lastWeek = today.dateByAddingTimeInterval( -7 * secondsPerDay )
        
        fetchRequest.predicate =
            NSPredicate( format: "workKey==%@", self.workDetail.key )
        
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
        operationQueue: PSOperationQueue,
        coreDataStack: OLDataStack,
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
    
    func numberOfRowsInSection( _ section: Int ) -> Int {
        
        return fetchedResultsController.sections?[section].objects.count ?? 0
    }
    
    func objectAtIndexPath( _ indexPath: IndexPath ) -> OLEBookItem? {
        
        guard let sections = fetchedResultsController.sections else {
            assertionFailure("Sections missing")
            return nil
        }
        
        let section = sections[indexPath.section]
        guard indexPath.row < section.objects.count else {
            assertionFailure( "row:\((indexPath as NSIndexPath).row) out of bounds" )
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
                    coreDataStack: coreDataStack
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
        
        highWaterMark = fetchedResultsController.count
        searchResults = SearchResults(start: 0, numFound: highWaterMark, pageSize: kPageSize )
        
        updateTableFooter( tableVC?.tableView, highWaterMark: highWaterMark, numFound: searchResults.numFound, text: text )
    }
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch(_ controller: FetchedEBookItemController) {
        
        if 0 == controller.count {
            
            newQuery( false, refreshControl: nil )
            
        }
        
        if 0 != controller.count {
            
            updateFooter()
        }
    }

    func fetchedResultsControllerWillChangeContent( _ controller: FetchedEBookItemController ) {
        tableVC?.tableView.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( _ controller: FetchedEBookItemController ) {
        tableVC?.tableView.endUpdates()
    }
    
    func fetchedResultsController( _ controller: FetchedEBookItemController,
                                   didChangeObject change: FetchedResultsObjectChange< OLEBookItem > ) {
        switch change {
        case let .insert(_, indexPath):
            tableVC?.tableView.insertRows(at: [indexPath], with: .automatic)
            break
            
        case let .delete(_, indexPath):
            tableVC?.tableView.deleteRows(at: [indexPath], with: .automatic)
            break
            
        case let .move(_, fromIndexPath, toIndexPath):
            tableVC?.tableView.moveRow(at: fromIndexPath, to: toIndexPath)
            
        case let .update(_, indexPath):
            tableVC?.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    func fetchedResultsController(_ controller: FetchedEBookItemController,
                                  didChangeSection change: FetchedResultsSectionChange< OLEBookItem >) {
        switch change {
        case let .insert(_, index):
            tableVC?.tableView.insertSections(IndexSet(integer: index), with: .automatic)
            
        case let .delete(_, index):
            tableVC?.tableView.deleteSections(IndexSet(integer: index), with: .automatic)
        }
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
                coreDataStack: coreDataStack,
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
