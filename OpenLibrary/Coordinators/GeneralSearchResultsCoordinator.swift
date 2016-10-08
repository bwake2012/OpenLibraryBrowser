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

import BNRCoreDataStack
import PSOperations

private let kGeneralSearchCache = "GeneralSearch"

private let kPageSize = 100

class GeneralSearchResultsCoordinator: OLQueryCoordinator, OLDataSource, FetchedResultsControllerDelegate {
    
    typealias FetchedOLGeneralSearchResultController = FetchedResultsController< OLGeneralSearchResult >
    
    weak var tableVC: OLSearchResultsTableViewController?

    var generalSearchOperation: Operation?
    var reachabilityOperation: Operation?
    
    private var cachedFetchedResultsController: FetchedOLGeneralSearchResultController?
        
    private var fetchedResultsController: FetchedOLGeneralSearchResultController {

        guard let frc = cachedFetchedResultsController else {
            
            let frc = buildFetchedResultsController( self, stack: coreDataStack, sortFields: sortFields )
            
            cachedFetchedResultsController = frc
            return frc
        }
        
        return frc
    }
    
    var searchKeys = [String: String]()
    
    private let defaultSortFields =
        [
            SortField( name: "sort_author_name", label: "Author", sort: .sortNone ),
            SortField( name: "title", label: "Title", sort: .sortNone ),
            SortField( name: "edition_count", label: "Edition Count", sort: .sortDown ),
            SortField( name: "ebook_count_i", label: "Electronic Editions", sort: .sortNone ),
            SortField( name: "first_publish_year", label: "Year First Published", sort: .sortNone )
        ]
    
    private var cachedSortFields = [SortField]()
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
            dispatch_async( dispatch_get_main_queue() ) {

                self.updateUI()
            }
        }
    }
    
    var searchResults = SearchResults()
    
    var sequence = 1
    var highWaterMark = 0
    var nextOffset = 0
    
    // MARK: Fetched Results Controller
    private func buildFetchedResultsController( delegate: GeneralSearchResultsCoordinator, stack: CoreDataStack, sortFields: [SortField] ) -> FetchedOLGeneralSearchResultController {
        
        let fetchRequest = NSFetchRequest( entityName: OLGeneralSearchResult.entityName )
        fetchRequest.predicate = NSPredicate( format: "sequence==\(sequence)" )

        fetchRequest.sortDescriptors = buildSortDescriptors( sortFields )
        assert( nil == fetchRequest.sortDescriptors || !fetchRequest.sortDescriptors!.isEmpty )
        fetchRequest.fetchBatchSize = 100
        
        let controller =
            FetchedOLGeneralSearchResultController(
                    fetchRequest: fetchRequest,
                    managedObjectContext: stack.mainQueueContext,
                    sectionNameKeyPath: nil,
                    cacheName: kGeneralSearchCache
                )
        
        controller.setDelegate( delegate )
        return controller
    }
    
    private func buildSortDescriptors( sortFields: [SortField] ) -> [NSSortDescriptor]? {
        
        var sortDescriptors = [NSSortDescriptor]()
        for sortField in sortFields {
            
            if .sortNone != sortField.sort {
                
                sortDescriptors.append(
                        NSSortDescriptor( key: sortField.name, ascending: sortField.sort.ascending )
                    )
            }
        }

        return !sortDescriptors.isEmpty ? sortDescriptors : [NSSortDescriptor( key: "index", ascending: true )]
    }
    
    // MARK: instance
    
    init( tableVC: OLSearchResultsTableViewController, coreDataStack: CoreDataStack, operationQueue: OperationQueue ) {
        
        self.tableVC = tableVC

        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: tableVC )
        
        if let searchState = SearchState.loadState() {
        
            searchKeys = searchState.searchFields
            cachedSortFields = searchState.sortFields
            searchResults = searchState.searchResults
            sequence = searchState.sequence
        }
        
        dispatch_async( dispatch_get_main_queue() ) {
            
            self.reachabilityOperation = OLReachabilityOperation( host: "openlibrary.org" ) {}
            self.reachabilityOperation!.userInitiated = true
            operationQueue.addOperation( self.reachabilityOperation! )
            
            OLLanguage.retrieveLanguages( operationQueue, coreDataStack: coreDataStack )

            self.updateFooter()
        
            self.updateUI()
        }
    }
    
    deinit {
        
        saveState()
    }
    
    func numberOfSections() -> Int {
        
        return fetchedResultsController.sections?.count ?? 0
    }

    func numberOfRowsInSection( section: Int ) -> Int {

        let rows = fetchedResultsController.sections?[section].objects.count ?? 0

        return rows
    }
    
    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLGeneralSearchResult? {
        
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
    
    func displayToCell( cell: OLTableViewCell, indexPath: NSIndexPath ) -> OLManagedObject? {
        
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
    
    func didSelectRowAtIndexPath( indexPath: NSIndexPath ) {
        
        if let object = objectAtIndexPath( indexPath ) where nil == object.work_detail {
            
            coordinatorIsBusy()
            
            let operation =
                SaveProvisionalObjectsOperation(
                    searchResult: object,
                    coreDataStack: coreDataStack
                ) {
                    
                    [weak self] in
                    
                    dispatch_async( dispatch_get_main_queue() ) {
                        
                        if let strongSelf = self {
                            
                            strongSelf.coordinatorIsNoLongerBusy()
                            
                            strongSelf.tableVC?.tableView.selectRowAtIndexPath(
                                indexPath, animated: true, scrollPosition: .None
                            )
                        }
                    }
            }
            
            operation.userInitiated = true
            operationQueue.addOperation( operation )
        }
    }

    func updateUI() {

        do {
            NSFetchedResultsController.deleteCacheWithName( kGeneralSearchCache )
            try fetchedResultsController.performFetch()
        }
        catch {

            print("Error in the fetched results controller: \(error).")
        }

        tableVC?.tableView.reloadData()
    }

    func newQuery( newSearchKeys: [String: String], userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        guard libraryIsReachable( tattle: true ) else {
            
//            updateHeader( "library is unreachable" )
            return
        }
        
        updateHeader( "" )
        if nil == generalSearchOperation {
            
            updateFooter( "Searching for Books..." )

            self.searchKeys = newSearchKeys
            if numberOfSections() > 0 {
                
                let top = NSIndexPath( forRow: Foundation.NSNotFound, inSection: 0 );
                tableVC?.tableView.scrollToRowAtIndexPath( top, atScrollPosition: UITableViewScrollPosition.Top, animated: true );
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
    
    private func enqueueSearch(
            searchKeys: [String: String],
            sequence: Int,
            offset: Int,
            pageSize: Int,
            userInitiated: Bool,
            refreshControl: UIRefreshControl?
        ) -> Operation {
        
        coordinatorIsBusy()
        
        let generalSearchOperation =
            GeneralSearchOperation(
                queryParms: searchKeys,
                sequence: sequence,
                offset: offset, limit: pageSize,
                coreDataStack: coreDataStack,
                updateResults: updateResults
            ) {
                
                dispatch_async( dispatch_get_main_queue() ) {
                        
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
        
        let queryClearOperation = GeneralSearchResultsDeleteOperation( coreDataStack: coreDataStack )
        
        queryClearOperation.userInitiated = false
        operationQueue.addOperation( queryClearOperation )
        
    }
    
    private func needAnotherPage( index: Int ) -> Bool {
        
        return
            nil == self.generalSearchOperation &&
            !searchKeys.isEmpty &&
            highWaterMark < searchResults.numFound &&
            index >= self.fetchedResultsController.count - 1
    }
    
    // MARK: SearchResultsUpdater
    private func updateResults(searchResults: SearchResults) -> Void {
        
        self.searchResults = searchResults
        self.highWaterMark = min(searchResults.numFound, searchResults.start + searchResults.pageSize )
 
    }
    
    private func updateHeader( string: String = "" ) {
        
        updateTableHeader( tableVC?.tableView, text: string )
    }
    
    private func updateFooter( text: String = "" ) -> Void {
        
        updateTableFooter( tableVC?.tableView, highWaterMark: highWaterMark, numFound: searchResults.numFound, text: text )
    }

    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch(controller: FetchedResultsController< OLGeneralSearchResult >) {

        highWaterMark = fetchedResultsController.count
        if 0 == highWaterMark && searchKeys.isEmpty {

            updateFooter( "Tap Search to Look for Books" )

        } else if nil == generalSearchOperation {
        
            updateFooter()
        }
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedOLGeneralSearchResultController ) {
        //        authorWorksTableVC?.tableView.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedOLGeneralSearchResultController ) {
        
        if let tableView = tableVC?.tableView {
            
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
        }
    }
    
    func fetchedResultsController( controller: FetchedOLGeneralSearchResultController,
                                   didChangeObject change: FetchedResultsObjectChange< OLGeneralSearchResult > ) {
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
    
    func fetchedResultsController(controller: FetchedOLGeneralSearchResultController,
                                  didChangeSection change: FetchedResultsSectionChange< OLGeneralSearchResult >) {
        
        switch change {
        case let .Insert(_, index):
            insertedSectionIndexes.addIndex( index )
        case let .Delete(_, index):
            deletedSectionIndexes.addIndex( index )
        }
    }
    
    // MARK: Utility
    func queueGetTitleThumbByID( indexPath: NSIndexPath, id: Int, url: NSURL ) {
        
        let TitleThumbnailGetOperation =
            ImageGetOperation( numberID: id, imageKeyName: "id", localURL: url, size: "S", type: "a" ) {
                [weak self] in
                
                if let strongSelf = self {
                    dispatch_async( dispatch_get_main_queue() ) {
                        
                        strongSelf.tableVC?.tableView.reloadRowsAtIndexPaths( [indexPath], withRowAnimation: .Automatic )
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
    
    func installAuthorDetailCoordinator( destVC: OLAuthorDetailViewController, indexPath: NSIndexPath ) {
        
        guard let searchResult = objectAtIndexPath( indexPath ) else {
            fatalError( "General Search Result object not retrieved." )
        }
        
        guard let workDetail = searchResult.work_detail else {
            
            fatalError( "General Search work detail missing." )
        }
        
        guard !workDetail.author_key.isEmpty else {
            
            fatalError( "work has no author keys!" )
        }
        
        guard let moc = workDetail.managedObjectContext else {
            
            fatalError( "work detail has no managed object!" )
        }
        
        guard let firstAuthor: OLAuthorDetail = OLAuthorDetail.findObject( workDetail.author_key, entityName: OLAuthorDetail.entityName, moc: moc ) else {
            
            fatalError( "work has no authors!" )
        }
        
        destVC.queryCoordinator =
            AuthorDetailCoordinator(
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    authorDetail: firstAuthor,
                    authorDetailVC: destVC
                )
    }
    
    func installWorkDetailCoordinator( destVC: OLWorkDetailViewController, indexPath: NSIndexPath ) {
        
        guard let searchResult = objectAtIndexPath( indexPath ) else {
            fatalError( "General Search Result object not retrieved." )
        }
        
        guard let workDetail = searchResult.work_detail else {
            
            fatalError( "General Search work detail missing." )
        }
        
        destVC.queryCoordinator =
            WorkDetailCoordinator(
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    workDetail: workDetail,
                    editionKeys: searchResult.edition_key,
                    workDetailVC: destVC
                )
    }
    
    func installCoverPictureViewCoordinator( destVC: OLPictureViewController, indexPath: NSIndexPath ) {
        
        guard let searchResult = objectAtIndexPath( indexPath ) else {
            fatalError( "General Search Result object not retrieved." )
        }
        
        destVC.queryCoordinator =
            PictureViewCoordinator(
                operationQueue: operationQueue,
                coreDataStack: coreDataStack,
                localURL: searchResult.localURL( "L", index: 0 ),
                imageID: searchResult.firstImageID,
                pictureType: searchResult.imageType,
                pictureVC: destVC
        )
        
    }

}
