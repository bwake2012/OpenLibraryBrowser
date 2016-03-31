//
//  AuthorDetailCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/21/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

import CoreData

import BNRCoreDataStack

typealias FetchedOLAuthorDetailController = FetchedResultsController< OLAuthorDetail >

let kAuthorDetailCache = "authorDetailSearch"

class AuthorDetailCoordinator: NSObject, FetchedResultsControllerDelegate {
    
    weak var authorDetailVC: OLAuthorDetailViewController?

    var operationQueue: OperationQueue?
    var coreDataStack: CoreDataStack?
    
    private lazy var fetchedResultsController: FetchedOLAuthorDetailController = {
        
        let fetchRequest = NSFetchRequest(entityName: OLAuthorDetail.entityName)
        fetchRequest.predicate = NSPredicate( format: "key==%@", "\(self.searchInfo.key)" )
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let frc = FetchedOLAuthorDetailController(fetchRequest: fetchRequest,
            managedObjectContext: self.coreDataStack!.mainQueueContext,
            sectionNameKeyPath: nil)
        
        frc.setDelegate( self )
        return frc
    }()
    
    var searchInfo: OLAuthorSearchResult
    
    init(
            operationQueue: OperationQueue,
            coreDataStack: CoreDataStack,
            searchInfo: OLAuthorSearchResult,
            authorDetailVC: OLAuthorDetailViewController
        ) {
        
        self.operationQueue = operationQueue
        self.coreDataStack = coreDataStack
        self.searchInfo = searchInfo
        self.authorDetailVC = authorDetailVC

        super.init()

        if nil == searchInfo.toDetail {
            performFetch()
        } else {
            updateUI( searchInfo.toDetail! )
        }
    }
    
    // MARK: FetchedResultsControllerDelegate
    func fetchedResultsControllerDidPerformFetch(controller: FetchedResultsController< OLAuthorDetail >) {
        
        if let authorDetail = controller.first {
            
            updateUI( authorDetail )
            
        } else {
            
            let getAuthorOperation =
            AuthorDetailGetOperation(
                queryText: searchInfo.key, parentObjectID: searchInfo.objectID,
                coreDataStack: coreDataStack!
                ) {
                    
                    dispatch_async( dispatch_get_main_queue() ) {}
            }
            
            getAuthorOperation.userInitiated = true
            operationQueue!.addOperation( getAuthorOperation )
        }
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedResultsController< OLAuthorDetail > ) {
        
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedResultsController< OLAuthorDetail > ) {
        
    }
    
    func fetchedResultsController( controller: FetchedResultsController< OLAuthorDetail >,
        didChangeObject change: FetchedResultsObjectChange< OLAuthorDetail > ) {
            switch change {
            case .Insert(_, _):
                print( "\(searchInfo.toDetail?.name)" )
                if let authorDetail = fetchedResultsController.first {
                    
                    updateUI( authorDetail )
                }
                
            case let .Delete(_, indexPath):
                break
                
            case let .Move(_, fromIndexPath, toIndexPath):
                break
                
            case let .Update(_, indexPath):
                break
            }
    }
    
    func fetchedResultsController(controller: FetchedResultsController< OLAuthorDetail >,
        didChangeSection change: FetchedResultsSectionChange< OLAuthorDetail >) {
            switch change {
            case let .Insert(_, index):
                break
                
            case let .Delete(_, index):
                break
            }
    }
    
    func updateUI( authorDetail: OLAuthorDetail ) {
        
        if let authorDetailVC = authorDetailVC {
            
            authorDetailVC.UpdateUI( authorDetail )
            
            if authorDetail.photos.count > 0 {
                
                let localURL = authorDetail.localURL( "M" )
                if !(authorDetailVC.displayImage( localURL )) {
                    
                    let url = localURL
                    let imageGetOperation =
                        ImageGetOperation( numberID: authorDetail.photos[0], imageKeyName: "ID", localURL: url, size: "M", type: "a" ) {
                            
                            dispatch_async( dispatch_get_main_queue() ) {
                                
                                authorDetailVC.displayImage( url )
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
            NSFetchedResultsController.deleteCacheWithName( kAuthorDetailCache )
            try self.fetchedResultsController.performFetch()
        }
        catch {
            print("Error in the fetched results controller: \(error).")
        }
        
    }
    
    func updateUI() -> Void {
        
        
    }
}
