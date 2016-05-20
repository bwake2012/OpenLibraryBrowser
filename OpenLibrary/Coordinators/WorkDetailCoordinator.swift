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

    var authorNames = [String]()
    var workDetail: OLWorkDetail?
    var workKey = ""
    
    var workDetailGetOperation: Operation?
    
    typealias FetchedWorkDetailController    = FetchedResultsController< OLWorkDetail >
    typealias FetchedWorkDetailChange        = FetchedResultsObjectChange< OLWorkDetail >
    typealias FetchedWorkDetailSectionChange = FetchedResultsSectionChange< OLWorkDetail >
    
    private lazy var fetchedResultsController: FetchedWorkDetailController = {
        
        let fetchRequest = NSFetchRequest( entityName: OLWorkDetail.entityName )
        
        let key = self.workKey
        fetchRequest.predicate = NSPredicate( format: "key==%@", "\(key)" )
        
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
            authorNames: [String],
            operationQueue: OperationQueue,
            coreDataStack: CoreDataStack,
            searchInfo: OLWorkDetail,
            workDetailVC: OLWorkDetailViewController
        ) {
        
        self.authorNames = authorNames
        self.workDetail = searchInfo
        self.workDetailVC = workDetailVC

        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
    }
    
    init(
        authorNames: [String],
        operationQueue: OperationQueue,
        coreDataStack: CoreDataStack,
        workKey: String,
        workDetailVC: OLWorkDetailViewController
        ) {
        
        assert( !workKey.isEmpty )
        
        self.authorNames = authorNames
        self.workDetail = nil
        self.workKey = workKey
        self.workDetailVC = workDetailVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
    }
    
    func updateUI( workDetail: OLWorkDetail ) {
        
        if let workDetailVC = workDetailVC {
            
            workDetailVC.updateUI( workDetail, authorName: authorNames.isEmpty ? "" : authorNames[0] )
            
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
            assert( false )
            return
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
            assert( false )
            return
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
}
