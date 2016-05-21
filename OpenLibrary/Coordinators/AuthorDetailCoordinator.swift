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

let kAuthorDetailCache = "authorDetailSearch"

class AuthorDetailCoordinator: OLQueryCoordinator, FetchedResultsControllerDelegate {
    
    weak var authorDetailVC: OLAuthorDetailViewController?

    var authorDetail: OLAuthorDetail?
    var authorKey: String
    var authorName: String
    var parentObjectID: NSManagedObjectID?
    
    var deluxeData = [[DeluxeData]]()
    
    var authorDetailGetOperation: Operation?
    
    typealias FetchedAuthorDetailController = FetchedResultsController< OLAuthorDetail >
    typealias FetchedAuthorDetailChange = FetchedResultsObjectChange< OLAuthorDetail >
    typealias FetchedAuthorDetailSectionChange = FetchedResultsSectionChange< OLAuthorDetail >
    
    private lazy var fetchedResultsController: FetchedAuthorDetailController = {
        
        let fetchRequest = NSFetchRequest( entityName: OLAuthorDetail.entityName )

        let key = self.authorKey
        fetchRequest.predicate = NSPredicate( format: "key==%@", "\(key)" )
        
        fetchRequest.sortDescriptors =
            [
                NSSortDescriptor(key: "name", ascending: true)
            ]
        
        let frc = FetchedAuthorDetailController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.coreDataStack.mainQueueContext,
            sectionNameKeyPath: nil,
            cacheName: kAuthorDetailCache )
        
        frc.setDelegate( self )
        return frc
    }()
    
    init(
            operationQueue: OperationQueue,
            coreDataStack: CoreDataStack,
            searchInfo: OLAuthorSearchResult,
            authorDetailVC: OLAuthorDetailViewController
        ) {
        
        self.authorDetail = searchInfo.toDetail
        if searchInfo.key.hasPrefix( kAuthorsPrefix ) {
            self.authorKey = searchInfo.key
        } else {
            self.authorKey = kAuthorsPrefix + searchInfo.key
        }
        self.authorName = searchInfo.name
        self.parentObjectID = searchInfo.objectID

        self.authorDetailVC = authorDetailVC

        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
    }
    
    init(
        operationQueue: OperationQueue,
        coreDataStack: CoreDataStack,
        searchInfo: OLGeneralSearchResult,
        authorDetailVC: OLAuthorDetailViewController
        ) {
        
        self.authorDetail = nil

        self.authorKey = searchInfo.author_key[0]
        if !self.authorKey.hasPrefix( kAuthorsPrefix ) {
            
            self.authorKey = kAuthorsPrefix + self.authorKey
        }
        self.authorName = searchInfo.author_name[0]
        
        self.authorDetailVC = authorDetailVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )

        assert( !authorKey.isEmpty )
    }
    
    init(
        operationQueue: OperationQueue,
        coreDataStack: CoreDataStack,
        authorKey: String,
        authorName: String,
        authorDetailVC: OLAuthorDetailViewController
        ) {
        
        self.authorDetail = nil
        
        self.authorKey = authorKey
        if !self.authorKey.hasPrefix( kAuthorsPrefix ) {
            
            self.authorKey = kAuthorsPrefix + self.authorKey
        }
        self.authorName = authorName
        
        self.authorDetailVC = authorDetailVC
        
        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
        
        assert( !authorKey.isEmpty )
    }
    
    func updateUI( authorDetail: OLAuthorDetail ) {
        
        if let authorDetailVC = authorDetailVC {
            
            authorDetailVC.updateUI( authorDetail )
            authorName = authorDetail.name
            
            if authorDetail.hasImage {
                
                let mediumURL = authorDetail.localURL( "M" )
                if !(authorDetailVC.displayImage( mediumURL )) {

                    let url = mediumURL
                    let imageGetOperation =
                        ImageGetOperation( numberID: authorDetail.firstImageID, imageKeyName: "ID", localURL: url, size: "M", type: authorDetail.imageType ) {
                            
                                dispatch_async( dispatch_get_main_queue() ) {
                                    
                                    authorDetailVC.displayImage( url )
                                }
                            }
                    
                    imageGetOperation.userInitiated = true
                    operationQueue.addOperation( imageGetOperation )
                    
                    authorDetailVC.displayImage( authorDetail.localURL( "S" ) )
                }
            }
        }
    }

    func updateUI() {
        
        do {
            NSFetchedResultsController.deleteCacheWithName( kAuthorDetailCache )
            try fetchedResultsController.performFetch()
        }
        catch let fetchError as NSError {
            print("Error in the fetched results controller: \(fetchError).")
        }
    }
    
    func newQuery( authorKey: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) {
        
        if nil == authorDetailGetOperation {
            let getAuthorOperation =
                AuthorDetailGetOperation(
                    queryText: authorKey,
                    parentObjectID: parentObjectID,
                    coreDataStack: coreDataStack
                ) {
                    [weak self] in
                    
                    if let strongSelf = self {
                        dispatch_async( dispatch_get_main_queue() ) {
                            
                            if let detail = strongSelf.authorDetail {
                                
                                strongSelf.updateUI( detail )
                            }
                        }
                    }
            }
            
            getAuthorOperation.userInitiated = true
            operationQueue.addOperation( getAuthorOperation )
        }
    }
    
    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLAuthorDetail? {
        
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
    
    func fetchedResultsControllerDidPerformFetch(controller: FetchedAuthorDetailController) {
        
        if 0 == controller.count {
            
            newQuery( authorKey, userInitiated: true, refreshControl: nil )
        } else {
            
            if let detail = objectAtIndexPath( NSIndexPath( forRow: 0, inSection: 0 ) ) {
                
                authorDetail = detail
                updateUI( detail )
            }
        }
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedAuthorDetailController ) {
        //        tableView?.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedAuthorDetailController ) {
        //        tableView?.endUpdates()
    }
    
    func fetchedResultsController( controller: FetchedAuthorDetailController,
                                   didChangeObject change: FetchedAuthorDetailChange ) {
        switch change {
        case let .Insert(_, indexPath):
            if let detail = objectAtIndexPath( NSIndexPath( forRow: 0, inSection: 0 ) ) {
                
                updateUI( detail )
                authorDetail = detail
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
                authorDetail = detail
            }
            break
        }
    }
    
    func fetchedResultsController( controller: FetchedAuthorDetailController,
                                   didChangeSection change: FetchedAuthorDetailSectionChange ) {
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
    
    func installAuthorWorksCoordinator( destVC: OLAuthorDetailWorksTableViewController ) {

        destVC.queryCoordinator =
            AuthorWorksCoordinator(
                    authorKey: authorKey,
                    authorNames: [authorName],
                    authorWorksTableVC: destVC,
                    coreDataStack: coreDataStack,
                    operationQueue: operationQueue
                )
    }

    func installAuthorEditionsCoordinator( destVC: OLAuthorDetailEditionsTableViewController ) {
        
        destVC.queryCoordinator =
            AuthorEditionsCoordinator(
                    authorKey: authorKey,
                    authorNames: [authorName],
                    withCoversOnly: false,
                    tableVC: destVC,
                    coreDataStack: coreDataStack,
                    operationQueue: operationQueue
                )
    }
    
    func installAuthorDeluxeDetailCoordinator( destVC: OLDeluxeDetailTableViewController ) {
        
        destVC.queryCoordinator =
            DeluxeDetailCoordinator(
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    deluxeData: authorDetail!.deluxeData,
                    imageType: authorDetail!.imageType,
                    deluxeDetailVC: destVC
                )
    }
    
    func installAuthorPictureCoordinator( destVC: OLPictureViewController ) {
        
        destVC.queryCoordinator =
            PictureViewCoordinator(
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    localURL: authorDetail!.localURL( "L", index: 0 ),
                    imageID: authorDetail!.firstImageID,
                    pictureType: authorDetail!.imageType,
                    pictureVC: destVC
                )
    }
}
