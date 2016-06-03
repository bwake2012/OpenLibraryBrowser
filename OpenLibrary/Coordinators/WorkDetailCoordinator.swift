//
//  WorkDetailCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/21/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

import CoreData

import BNRCoreDataStack

private let kWorkDetailCache = "workDetailSearch"

class WorkDetailCoordinator: OLQueryCoordinator, FetchedResultsControllerDelegate {
    
    weak var workDetailVC: OLWorkDetailViewController?

    var workDetail: OLWorkDetail?
    var workKey: String
    
    var workDetailGetOperation: Operation?
    var authorDetailGetOperation: Operation?
    
    typealias FetchedWorkDetailController    = FetchedResultsController< OLWorkDetail >
    typealias FetchedWorkDetailChange        = FetchedResultsObjectChange< OLWorkDetail >
    typealias FetchedWorkDetailSectionChange = FetchedResultsSectionChange< OLWorkDetail >
    
    private lazy var fetchedResultsController: FetchedWorkDetailController = {
        
        let fetchRequest = NSFetchRequest( entityName: OLWorkDetail.entityName )
        
        let key = self.workKey
        
        let secondsPerDay = NSTimeInterval( 24 * 60 * 60 )
        let today = NSDate()
        let yesterday = today.dateByAddingTimeInterval( -secondsPerDay )
        
        fetchRequest.predicate = NSPredicate( format: "key==%@ && retrieval_date > %@", "\(key)", yesterday )
        
        fetchRequest.sortDescriptors =
            [
                NSSortDescriptor(key: "title", ascending: true)
            ]
        
        let frc = FetchedWorkDetailController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.coreDataStack.mainQueueContext,
            sectionNameKeyPath: nil,
            cacheName: kWorkDetailCache )
        
        frc.setDelegate( self )
        return frc
    }()
    
    init(
            operationQueue: OperationQueue,
            coreDataStack: CoreDataStack,
            searchInfo: OLWorkDetail,
            workDetailVC: OLWorkDetailViewController
        ) {
        
        self.workDetail = searchInfo
        self.workKey = searchInfo.key
        self.workDetailVC = workDetailVC

        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
    }
    
    init(
        operationQueue: OperationQueue,
        coreDataStack: CoreDataStack,
        workKey: String,
        workDetailVC: OLWorkDetailViewController
        ) {
        
        assert( !workKey.isEmpty )
        
        self.workDetail = nil
        self.workKey = workKey
        self.workDetailVC = workDetailVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
    }
    
    func updateUI( workDetail: OLWorkDetail ) {
        
        if let workDetailVC = workDetailVC {
            
            retrieveAuthors( workDetail )
            
            workDetailVC.updateUI( workDetail )
            
            if workDetail.hasImage {
                
                let localURL = workDetail.localURL( "M" )
                if !( workDetailVC.displayImage( localURL ) ) {

                    let url = localURL
                    let imageGetOperation =
                        ImageGetOperation( numberID: workDetail.covers[0], imageKeyName: "id", localURL: url, size: "M", type: "a" ) {
                            
                            [weak self] in
                            
                            if nil != self {

                                dispatch_async( dispatch_get_main_queue() ) {
                                    
                                    workDetailVC.displayImage( url )
                                }
                            }
                    }
                    
                    imageGetOperation.userInitiated = true
                    operationQueue.addOperation( imageGetOperation )
                    
                    workDetailVC.displayImage( workDetail.localURL( "S" ) )
                }
            }
        }
    }
    
    func getSearchInfo( objectID: NSManagedObjectID ) {
        
        dispatch_async( dispatch_get_main_queue() ) {
            if let workDetail = self.coreDataStack.mainQueueContext.objectWithID( objectID ) as? OLWorkDetail {
                
                self.workDetail = workDetail
            }
        }
    }
    
    func updateUI() {
        
        do {
            NSFetchedResultsController.deleteCacheWithName( kWorkDetailCache )
            try fetchedResultsController.performFetch()
        }
        catch let fetchError as NSError {
            print("Error in the fetched results controller: \(fetchError).")
        }
    }
    
    func newQuery( workKey: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        if nil == workDetailGetOperation {
            workDetailGetOperation =
                WorkDetailGetOperation(
                    queryText: workKey,
                    coreDataStack: coreDataStack,
                    resultHandler: getSearchInfo
                ) {
                    [weak self] in
                    
                    if let strongSelf = self {
                        dispatch_async( dispatch_get_main_queue() ) {
                            
                            if let detail = strongSelf.workDetail {
                                
                                strongSelf.updateUI( detail )
                            }
                        }
                    }
            }
            
            workDetailGetOperation!.userInitiated = true
            operationQueue.addOperation( workDetailGetOperation! )
        }
    }
    
    func retrieveAuthors ( workDetail: OLWorkDetail ) {
        
        if nil == authorDetailGetOperation {
            let authorNames = workDetail.author_names
            var authors = workDetail.authors
            
            if authorNames.count < authors.count {
                
                let firstOLID = authors.removeFirst()
                
                for olid in authors {
                    
                    if !olid.isEmpty {
                        let operation =
                            AuthorDetailGetOperation(
                                    queryText: olid,
                                    parentObjectID: nil,
                                    coreDataStack: coreDataStack
                                ) {}
                        operationQueue.addOperation( operation )
                    }
                }
                
                if !firstOLID.isEmpty {
                   
                    authorDetailGetOperation =
                        AuthorDetailGetOperation(
                                queryText: firstOLID,
                                parentObjectID: nil,
                                coreDataStack: coreDataStack
                            ) {
                                
                                [weak self] in
                                
                                if let strongSelf = self {

                                    dispatch_async( dispatch_get_main_queue() ) {
                                        
                                        strongSelf.updateUI( workDetail )
                    
                                        strongSelf.authorDetailGetOperation = nil
                                    }
                                }
                            }
                    operationQueue.addOperation( authorDetailGetOperation! )
                }
            }
        }
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
    
    func refreshQuery( refreshControl: UIRefreshControl? ) {
        
        newQuery( self.workKey, userInitiated: true, refreshControl: refreshControl )
    }
    
    
    // MARK: FetchedResultsControllerDelegate
    
    func fetchedResultsControllerDidPerformFetch(controller: FetchedWorkDetailController) {
        
        if 0 == controller.count {
            
            newQuery( workKey, userInitiated: true, refreshControl: nil )

        } else {
            
            if let detail = objectAtIndexPath( NSIndexPath( forRow: 0, inSection: 0 ) ) {
                
                workDetail = detail
                updateUI( detail )
            }
        }
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedWorkDetailController ) {
        //        tableView?.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedWorkDetailController ) {
        //        tableView?.endUpdates()
    }
    
    func fetchedResultsController( controller: FetchedWorkDetailController,
                                   didChangeObject change: FetchedWorkDetailChange ) {
        switch change {
        case let .Insert(_, indexPath):
            if let detail = objectAtIndexPath( NSIndexPath( forRow: 0, inSection: 0 ) ) {
                
                updateUI( detail )
                workDetail = detail
            }
            break
            
        case let .Delete(_, indexPath):
            // tableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            break
            
        case let .Move(_, fromIndexPath, toIndexPath):
            // tableVC.tableView.moveRowAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
            break
            
        case let .Update(_, indexPath):
            if let detail = objectAtIndexPath( NSIndexPath( forRow: 0, inSection: 0 ) ) {
                
                updateUI( detail )
                workDetail = detail
            }
            break
        }
    }
    
    func fetchedResultsController( controller: FetchedWorkDetailController,
                                   didChangeSection change: FetchedWorkDetailSectionChange ) {
        switch change {
        case let .Insert(_, index):
            // tableVC.tableView.insertSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
            break
            
        case let .Delete(_, index):
            // tableVC.tableView.deleteSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
            break
        }
    }
    
    // MARK: Utility
    
    func findAuthorDetailInStack( navigationController: UINavigationController ) -> OLAuthorDetailViewController? {
        
        var index = navigationController.viewControllers.count - 1
        repeat {
            
            let vc = navigationController.viewControllers[index]
            
            if let authorDetailVC = vc as? OLAuthorDetailViewController {
                
                if authorDetailVC.queryCoordinator?.authorKey == workDetail?.author_key {
                    
                    return authorDetailVC
                }
            }
            
            index -= 1
            
        } while index > 0
        
        return nil
    }

    // MARK: install query coordinators
    
    func installWorkDetailEditionsQueryCoordinator( destVC: OLWorkDetailEditionsTableViewController ) {
        
        let workKey = self.workKey
        assert( !workKey.isEmpty )
        
        destVC.queryCoordinator =
            WorkEditionsCoordinator(
                workKey: workKey,
                withCoversOnly: true,
                tableVC: destVC,
                coreDataStack: self.coreDataStack,
                operationQueue: self.operationQueue
        )
     }
    
    func installWorkDeluxeDetailCoordinator( destVC: OLDeluxeDetailTableViewController ) {
        
        guard let workDetail = workDetail else {
            fatalError( "Work Detail object not retrieved.")
        }
        
        destVC.queryCoordinator =
            DeluxeDetailCoordinator(
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    deluxeData: workDetail.deluxeData,
                    imageType: workDetail.imageType,
                    deluxeDetailVC: destVC
                )
    }
    
    func installCoverPictureViewCoordinator( destVC: OLPictureViewController ) {
    
        guard let workDetail = workDetail else {
            fatalError( "Work Detail object not retrieved.")
        }
        
        destVC.queryCoordinator =
            PictureViewCoordinator(
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    localURL: workDetail.localURL( "L", index: 0 ),
                    imageID: workDetail.firstImageID,
                    pictureType: workDetail.imageType,
                    pictureVC: destVC
                )

    }
    
    func installAuthorDetailCoordinator( destVC: OLAuthorDetailViewController ) {
        
        guard let workDetail = workDetail else {
            fatalError( "Work Detail object not retrieved.")
        }
        
        destVC.queryCoordinator =
            AuthorDetailCoordinator(
                operationQueue: operationQueue,
                coreDataStack: coreDataStack,
                authorKey: workDetail.author_key,
                authorDetailVC: destVC
            )
    }
}
