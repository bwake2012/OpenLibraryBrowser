//
//  GeneralSearchResultsCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/10/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import UIKit
import CoreData

//import BNRCoreDataStack
import PSOperations

private let kGeneralSearchCache = "GeneralSearch"

private let kPageSize = 100

class GeneralSearchResultsCoordinator: OLQueryCoordinator, OLDataSource {
    
    typealias FetchedOLGeneralSearchResultController = NSFetchedResultsController< OLGeneralSearchResult >
    
    weak var tableVC: OLSearchResultsTableViewController?

    var generalSearchOperation: PSOperation?
    var reachabilityOperation: PSOperation?
    
    fileprivate var cachedFetchedResultsController: FetchedOLGeneralSearchResultController?
        
    fileprivate var fetchedResultsController: FetchedOLGeneralSearchResultController {

        guard let frc = cachedFetchedResultsController else {
            
            let frc = buildFetchedResultsController( self, stack: dataStack, sortFields: sortFields )
            
            cachedFetchedResultsController = frc
            return frc
        }
        
        return frc
    }
    
    var searchKeys = [String: String]()
    
    fileprivate let defaultSortFields =
        [
            SortField(
                name: "sort_author_name",
                label: NSLocalizedString( "Author", comment: "sort by author name" ),
                sort: .sortNone ),
            SortField(
                name: "title",
                label: NSLocalizedString( "Title", comment: "sort by title" ),
                sort: .sortNone ),
            SortField(
                name: "edition_count",
                label: NSLocalizedString( "Edition Count", comment: "sort by the number of editions" ),
                sort: .sortDown ),
            SortField(
                name: "ebook_count_i",
                label: NSLocalizedString( "Electronic Editions", comment: "sort by the number of electronic editions" ),
                sort: .sortNone ),
            SortField(
                name: "first_publish_year",
                label: NSLocalizedString( "Year First Published", comment: "sort by the year the work was first published" ),
                sort: .sortNone )
        ]
    
    fileprivate var cachedSortFields = [SortField]()
    var sortFields: [SortField] {
        
        get {
            
            if cachedSortFields.isEmpty {
                return defaultSortFields
            } else {
                return cachedSortFields
            }
        }
        
        set( newSortFields ) {
            
            cachedSortFields = newSortFields
            saveState()
            cachedFetchedResultsController = nil
            DispatchQueue.main.async {
                
                [weak self] in

                self?.updateUI()
            }
        }
    }
    
    var searchResults = SearchResults()
    
    var sequence = 1
    var highWaterMark = 0
    var nextOffset = 0
    
    // MARK: instance
    
    init( tableVC: OLSearchResultsTableViewController, dataStack: OLDataStack, operationQueue: PSOperationQueue ) {
        
        self.tableVC = tableVC

        super.init( operationQueue: operationQueue, dataStack: dataStack, viewController: tableVC )
        
        if let searchState = SearchState.loadState() {
        
            searchKeys = searchState.searchFields
            cachedSortFields = searchState.sortFields
            searchResults = searchState.searchResults
            sequence = searchState.sequence
        }
        
        DispatchQueue.main.async {
            
            [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.reachabilityOperation = OLReachabilityOperation( host: "openlibrary.org" ) {}
            strongSelf.reachabilityOperation!.userInitiated = true
            operationQueue.addOperation( strongSelf.reachabilityOperation! )
            
            strongSelf.updateFooter()
        }
    }
    
    deinit {
        
        saveState()
    }
    
    func numberOfSections() -> Int {
        
        // NSLog( "numberOfSections" )
        return fetchedResultsController.sections?.count ?? 0
    }

    func numberOfRowsInSection( _ section: Int ) -> Int {

        // NSLog( "numberOfRowsInSection" )

        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func objectAtIndexPath( _ indexPath: IndexPath ) -> OLGeneralSearchResult? {
        
        // NSLog( "objectAtIndexPath" )
        
        guard let sections = fetchedResultsController.sections else {
            fatalError("Sections missing")
        }
        
        let section = sections[indexPath.section]
        guard let itemsInSection = section.objects as? [OLGeneralSearchResult] else {
            fatalError("Missing items")
        }
        
        let result = itemsInSection[indexPath.row]
        
        return result
    }
    
    @discardableResult func displayToCell( _ cell: OLTableViewCell, indexPath: IndexPath ) -> OLManagedObject? {
        
        guard let cell = cell as? GeneralSearchResultTableViewCell else {
            assert( false )
            return nil
        }
        
        guard let result = objectAtIndexPath( indexPath ) else { return nil }

        if let tableVC = tableVC {
            
            cell.configure( tableVC.tableView, indexPath: indexPath, key: result.key, data: result )
            if !displayThumbnail( result, cell: cell ) {
                
                result.cover_i = 0
            }
        }
        
        return result
    }
    
    func didSelectRowAtIndexPath( _ indexPath: IndexPath ) {
        
        if let object = objectAtIndexPath( indexPath ) , nil == object.work_detail {
            
            coordinatorIsBusy()
            
            let operation =
                SaveProvisionalObjectsOperation(
                    searchResult: object,
                    dataStack: dataStack
                ) {
                    
                    [weak self] in
                    
                    DispatchQueue.main.async {
                        
                        if let strongSelf = self {
                            
                            strongSelf.coordinatorIsNoLongerBusy()
                            
                            strongSelf.tableVC?.tableView.selectRow(
                                at: indexPath, animated: true, scrollPosition: .none
                            )
                        }
                    }
            }
            
            operation.userInitiated = true
            operationQueue.addOperation( operation )
        }
    }

    func updateUI() {

        // NSLog( "starting UI Updates - perform fetch" )
        do {
//            NSFetchedResultsController< OLGeneralSearchResult >.deleteCache( withName: kGeneralSearchCache )
            
            // NSLog( "perform fetch" )
            try fetchedResultsController.performFetch()

            controllerDidPerformFetch( fetchedResultsController )
        }
        catch {

            // NSLog( "Error in the fetched results controller: \(error)." )
        }

        tableVC?.tableView.reloadData()
    }

    func newQuery( _ newSearchKeys: [String: String], userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        guard libraryIsReachable( tattle: true ) else {
            
//            updateHeader( "library is unreachable" )
            return
        }
        
        updateHeader( "" )
        if nil == generalSearchOperation {
            
            updateFooter( "Searching for Books..." )

            self.searchKeys = newSearchKeys
            if numberOfSections() > 0 {
                
                let top = IndexPath( row: Foundation.NSNotFound, section: 0 );
                tableVC?.tableView.scrollToRow( at: top, at: UITableView.ScrollPosition.top, animated: true );
            }
        
            self.sequence += 1
            self.searchResults = SearchResults()
            self.highWaterMark = 0
            self.nextOffset = kPageSize
            
            saveState()
            
            generalSearchOperation =
                enqueueSearch(
                        searchKeys,
                        sequence: sequence,
                        offset: highWaterMark,
                        pageSize: kPageSize,
                        userInitiated: userInitiated,
                        refreshControl: refreshControl
                    )
            
            cachedFetchedResultsController = nil
            updateUI()
        }
    }
    
    func nextQueryPage() -> Void {
        
        guard libraryIsReachable( tattle: true ) else {
            
//            updateHeader( "library is unreachable" )
            return
        }
            
        updateHeader( "" )
        if nil == self.generalSearchOperation && !searchKeys.isEmpty && highWaterMark < searchResults.numFound {
            
            updateFooter( "Fetching More Books..." )

            nextOffset = highWaterMark + kPageSize
            
            generalSearchOperation =
                enqueueSearch(
                        self.searchKeys,
                        sequence: sequence,
                        offset: highWaterMark, pageSize: kPageSize,
                        userInitiated: false,
                        refreshControl: nil
                    )
        }
    }
    
    fileprivate func enqueueSearch(
            _ searchKeys: [String: String],
            sequence: Int,
            offset: Int,
            pageSize: Int,
            userInitiated: Bool,
            refreshControl: UIRefreshControl?
        ) -> PSOperation {
        
        coordinatorIsBusy()
        
        let generalSearchOperation =
            GeneralSearchOperation(
                queryParms: searchKeys,
                sequence: sequence,
                offset: offset, limit: pageSize,
                dataStack: dataStack,
                updateResults: updateResults
            ) {
                
                DispatchQueue.main.async {
                        
                    [weak self] in

                    if let strongSelf = self {
                    
                        strongSelf.coordinatorIsNoLongerBusy()

                        refreshControl?.endRefreshing()
                        strongSelf.updateFooter()
                        
                        strongSelf.saveState()
                        
                        strongSelf.generalSearchOperation = nil
                    }
                }
        }

        generalSearchOperation.userInitiated = userInitiated
        operationQueue.addOperation( generalSearchOperation )
        
        return generalSearchOperation
    }
    
    func clearQuery() {
        
        let queryClearOperation = GeneralSearchResultsDeleteOperation( dataStack: dataStack )
        
        queryClearOperation.userInitiated = false
        operationQueue.addOperation( queryClearOperation )
        
    }
    
    fileprivate func needAnotherPage( _ index: Int ) -> Bool {
        
        return
            nil == self.generalSearchOperation &&
            !searchKeys.isEmpty &&
            highWaterMark < searchResults.numFound &&
            index >= numberOfRowsInSection( 0 ) - 1
    }
    
    // MARK: SearchResultsUpdater
    fileprivate func updateResults(_ searchResults: SearchResults) -> Void {
        
        self.searchResults = searchResults
        self.highWaterMark = min(searchResults.numFound, searchResults.start + searchResults.pageSize )
 
    }
    
    fileprivate func updateHeader( _ string: String = "" ) {
        
        updateTableHeader( tableVC?.tableView, text: string )
    }
    
    fileprivate func updateFooter( _ text: String = "" ) -> Void {
        
        updateTableFooter( tableVC?.tableView, highWaterMark: highWaterMark, numFound: searchResults.numFound, text: text )
    }

    // MARK: FetchedResultsControllerDelegate
    func controllerDidPerformFetch(_ controller: FetchedOLGeneralSearchResultController ) {

        // NSLog( "fetchedResultsControllerDidPerformFetch" )
        highWaterMark = numberOfRowsInSection( 0 )
        if 0 == highWaterMark && searchKeys.isEmpty {

            updateFooter( "Tap Search to Look for Books" )

        } else if nil == generalSearchOperation {
        
            updateFooter()
        }
    }
    
    // MARK: Utility
    func queueGetTitleThumbByID( _ indexPath: IndexPath, id: Int, url: URL ) {
        
        let TitleThumbnailGetOperation =
            ImageGetOperation( numberID: id, imageKeyName: "id", localURL: url, size: "S", type: "a" ) {
                [weak self] in
                
                DispatchQueue.main.async {
                        
                    if let strongSelf = self {

                        strongSelf.tableVC?.tableView.reloadRows( at: [indexPath], with: .automatic )
                    }
                }
        }
        
        TitleThumbnailGetOperation.userInitiated = true
        operationQueue.addOperation( TitleThumbnailGetOperation )
    }
    
    func coordinatorIsBusy() -> Void {
        
        if let tableVC = tableVC {

            tableVC.coordinatorIsBusy()
        }
    }
    
    func coordinatorIsNoLongerBusy() -> Void {
    
        if let tableVC = tableVC {
            
            tableVC.coordinatorIsNoLongerBusy()
        }
    }
    
    func saveState() -> Void {
        
        let searchState =
            SearchState(
                    searchFields: searchKeys,
                    sortFields: sortFields,
                    searchResults: searchResults,
                    sequence: sequence
                )
        searchState.saveState()
    }
    
    // MARK: set coordinator for view controller
    
    func installAuthorDetailCoordinator( _ destVC: OLAuthorDetailViewController, authorKey: String ) {
        
        destVC.queryCoordinator =
            AuthorDetailCoordinator(
                operationQueue: operationQueue,
                dataStack: dataStack,
                authorKey: authorKey,
                authorDetailVC: destVC
        )
    }
    
    func installAuthorDetailCoordinator( _ destVC: OLAuthorDetailViewController, indexPath: IndexPath ) {
        
        guard let searchResult = objectAtIndexPath( indexPath ) else {
            fatalError( "General Search Result object not retrieved." )
        }
        
        guard let workDetail = searchResult.work_detail else {
            
            fatalError( "General Search work detail missing." )
        }
        
        guard !workDetail.author_key.isEmpty else {
            
            fatalError( "work has no author keys!" )
        }
        
        destVC.queryCoordinator =
            AuthorDetailCoordinator(
                    operationQueue: operationQueue,
                    dataStack: dataStack,
                    authorKey: workDetail.author_key,
                    authorDetailVC: destVC
                )
    }
    
    func installAuthorsTableViewCoordinator( _ destVC: OLAuthorsTableViewController, indexPath: IndexPath ) {
        
        guard let searchResult = objectAtIndexPath( indexPath ) else {
            fatalError( "General Search Result object not retrieved." )
        }
        
        destVC.queryCoordinator =
            AuthorsCoordinator(
                    keys: searchResult.author_key,
                    viewController: destVC,
                    operationQueue: operationQueue,
                    dataStack: dataStack
                )
    }
    
    func installWorkDetailCoordinator( _ destVC: OLWorkDetailViewController, indexPath: IndexPath ) {
        
        guard let searchResult = objectAtIndexPath( indexPath ) else {
            fatalError( "General Search Result object not retrieved." )
        }
        
        guard let workDetail = searchResult.work_detail else {
            
            fatalError( "General Search work detail missing." )
        }
        
        destVC.queryCoordinator =
            WorkDetailCoordinator(
                    operationQueue: operationQueue,
                    dataStack: dataStack,
                    workDetail: workDetail,
                    editionKeys: searchResult.edition_key,
                    workDetailVC: destVC
                )
    }
    
    func installCoverPictureViewCoordinator( _ destVC: OLPictureViewController, indexPath: IndexPath ) {
        
        guard let searchResult = objectAtIndexPath( indexPath ) else {
            fatalError( "General Search Result object not retrieved." )
        }
        
        destVC.queryCoordinator =
            PictureViewCoordinator(
                operationQueue: operationQueue,
                dataStack: dataStack,
                localURL: searchResult.localURL( "L", index: 0 ),
                imageID: searchResult.firstImageID,
                pictureType: searchResult.imageType,
                pictureVC: destVC
        )
        
    }

}

extension GeneralSearchResultsCoordinator: NSFetchedResultsControllerDelegate {
    
    // MARK: Fetched Results Controller

    fileprivate func buildSortDescriptors( _ sortFields: [SortField] ) -> [NSSortDescriptor]? {
        
        var sortDescriptors = [NSSortDescriptor]()
        for sortField in sortFields {
            
            if .sortNone != sortField.sort {
                
                sortDescriptors.append(
                    NSSortDescriptor( key: sortField.name, ascending: sortField.sort.ascending )
                )
            }
        }
        
        sortDescriptors.append( NSSortDescriptor( key: "index", ascending: true ) )
        
        return sortDescriptors
    }

    fileprivate func buildFetchedResultsController( _ delegate: GeneralSearchResultsCoordinator, stack: OLDataStack, sortFields: [SortField] ) -> FetchedOLGeneralSearchResultController {
        
        // NSLog( "Building Fetched Results Controller" )
        
        let fetchRequest = OLGeneralSearchResult.buildFetchRequest()
        fetchRequest.predicate = NSPredicate( format: "sequence==%@", self.sequence as NSNumber )
        
        fetchRequest.sortDescriptors = buildSortDescriptors( sortFields )
        assert( nil == fetchRequest.sortDescriptors || !fetchRequest.sortDescriptors!.isEmpty )
        fetchRequest.fetchBatchSize = 100
        
        let controller =
            FetchedOLGeneralSearchResultController(
                fetchRequest: fetchRequest,
                managedObjectContext: stack.mainQueueContext,
                sectionNameKeyPath: nil,
                cacheName: nil          // kGeneralSearchCache
        )
        
        controller.delegate = self
        return controller
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
            fatalError("Unexpected NSFetchedResultsChangeType")
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
