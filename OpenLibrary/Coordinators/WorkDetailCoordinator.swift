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

typealias FetchedOLWorkDetailController = FetchedResultsController< OLWorkDetail >

let kWorkDetailCache = "workDetailSearch"

class WorkDetailCoordinator: NSObject, FetchedResultsControllerDelegate {
    
    weak var workDetailVC: OLWorkDetailViewController?

    var operationQueue: OperationQueue?
    var coreDataStack: CoreDataStack?
    
    private lazy var fetchedResultsController: FetchedOLWorkDetailController = {
        
        let fetchRequest = NSFetchRequest(entityName: OLWorkDetail.entityName)
        fetchRequest.predicate = NSPredicate( format: "key==%@", "/works/\(self.searchInfo.key)" )
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let frc = FetchedOLWorkDetailController(fetchRequest: fetchRequest,
            managedObjectContext: self.coreDataStack!.mainQueueContext,
            sectionNameKeyPath: nil)
        
        frc.setDelegate( self )
        return frc
    }()
    
    var searchInfo: OLWorkDetail.SearchInfo
    
    init(
            operationQueue: OperationQueue,
            coreDataStack: CoreDataStack,
            searchInfo: OLWorkDetail.SearchInfo,
            workDetailVC: OLWorkDetailViewController
        ) {
        
        self.operationQueue = operationQueue
        self.coreDataStack = coreDataStack
        self.searchInfo = searchInfo
        self.workDetailVC = workDetailVC

        super.init()

        performFetch()
    }
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch(controller: FetchedResultsController< OLWorkDetail >) {
        
        if let workDetail = controller.first {
            
            updateUI( workDetail )
            
        } else {
            
            let getWorkOperation =
            WorkDetailGetOperation(
                queryText: searchInfo.key,
                coreDataStack: coreDataStack!
                ) {
                    
                    dispatch_async( dispatch_get_main_queue() ) {}
            }
            
            getWorkOperation.userInitiated = true
            operationQueue!.addOperation( getWorkOperation )
        }
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedResultsController< OLWorkDetail > ) {
        
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedResultsController< OLWorkDetail > ) {
        
    }
    
    func fetchedResultsController( controller: FetchedResultsController< OLWorkDetail >,
        didChangeObject change: FetchedResultsObjectChange< OLWorkDetail > ) {
            switch change {
            case .Insert(_, _):
                if let workDetail = fetchedResultsController.first {
                    
                    updateUI( workDetail )
                }
                
            case let .Delete(_, indexPath):
                break
                
            case let .Move(_, fromIndexPath, toIndexPath):
                break
                
            case let .Update(_, indexPath):
                break
            }
    }
    
    func fetchedResultsController(controller: FetchedResultsController< OLWorkDetail >,
        didChangeSection change: FetchedResultsSectionChange< OLWorkDetail >) {
            switch change {
            case let .Insert(_, index):
                break
                
            case let .Delete(_, index):
                break
            }
    }
    
    func updateUI( workDetail: OLWorkDetail ) {
        
        if let workDetailVC = workDetailVC {
            
            workDetailVC.UpdateUI( workDetail )
            
            if workDetail.covers.count > 0 {
                
                let localURL = workDetail.localURL( "B" )
                if !(workDetailVC.displayImage( localURL )) {
                    
                    let url = localURL
                    let imageGetOperation =
                        ImageGetOperation( numberID: workDetail.covers[0], imageKeyName: "id", localURL: url, size: "M", type: "a" ) {
                            
                            dispatch_async( dispatch_get_main_queue() ) {
                                
                                workDetailVC.displayImage( url )
                            }
                    }
                    
                    imageGetOperation.userInitiated = true
                    operationQueue!.addOperation( imageGetOperation )
                }
            }
        }
    }

    func performFetch() {
        
        do {
            NSFetchedResultsController.deleteCacheWithName( kWorkDetailCache )
            try fetchedResultsController.performFetch()
        }
        catch {
            print("Error in the fetched results controller: \(error).")
        }
        
    }
    
}
