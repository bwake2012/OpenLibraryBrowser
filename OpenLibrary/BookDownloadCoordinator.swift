//
//  BookDownloadCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 18/6/2016.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData

import BNRCoreDataStack

let kEBookFileCache = "eBookXMLFileCache"

class BookDownloadCoordinator: OLQueryCoordinator, FetchedResultsControllerDelegate {
    
    weak var downloadVC: OLBookDownloadViewController?
    
    private var bookURL: NSURL
    private var eBookKey = ""

    var xmlFileDownloadOperation: InternetArchiveEbookInfoGetOperation?
    
    typealias FetchedEBookFileController    = FetchedResultsController< OLEBookFile >
    typealias FetchedEBookFileChange        = FetchedResultsObjectChange< OLEBookFile >
    typealias FetchedEBookFileSectionChange = FetchedResultsSectionChange< OLEBookFile >
    
    private lazy var fetchedEBookFileController: FetchedEBookFileController = {
        
        let fetchRequest = NSFetchRequest( entityName: OLEBookFile.entityName )
        
//        let secondsPerDay = NSTimeInterval( 24 * 60 * 60 )
//        let today = NSDate()
//        let yesterday = today.dateByAddingTimeInterval( -secondsPerDay )
        
        fetchRequest.predicate = NSPredicate( format: "eBookKey==%@", "\(self.eBookKey)" )
        
        fetchRequest.sortDescriptors =
            [
                NSSortDescriptor( key: "format", ascending: true ),
                NSSortDescriptor( key: "name", ascending: true )
            ]
        
        let frc = FetchedEBookFileController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.coreDataStack.mainQueueContext,
            sectionNameKeyPath: nil,
            cacheName: kEBookFileCache )
        
        frc.setDelegate( self )
        return frc
    }()
    
    init(
        operationQueue: OperationQueue,
        coreDataStack: CoreDataStack,
        bookURL: NSURL,
        downloadVC: OLBookDownloadViewController
    ) {
    
        self.bookURL = bookURL
        self.eBookKey = bookURL.lastPathComponent ?? ""
    
        self.downloadVC = downloadVC

        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
    }
    
    func updateUI() {
        
        if nil != downloadVC {
            do {
                NSFetchedResultsController.deleteCacheWithName( kEBookFileCache )
                try fetchedEBookFileController.performFetch()
            }
            catch let fetchError as NSError {
                print("Error in the fetched results controller: \(fetchError).")
            }
        }
    }

    func newQuery( eBookKey: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) -> Void {
        
        if nil == xmlFileDownloadOperation {
            xmlFileDownloadOperation =
                InternetArchiveEbookInfoGetOperation(
                    eBookKey: eBookKey,
                    coreDataStack: coreDataStack
                ) {}
            
            xmlFileDownloadOperation!.userInitiated = true
            operationQueue.addOperation( xmlFileDownloadOperation! )
        }
    }
    
    func cancelOperations() {
        
        xmlFileDownloadOperation?.cancel()
    }

    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLEBookFile? {
        
        guard let sections = fetchedEBookFileController.sections else {
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
    
    func fetchedResultsControllerDidPerformFetch(controller: FetchedEBookFileController) {
        
        if 0 == controller.count {
            
            newQuery( eBookKey, userInitiated: true, refreshControl: nil )
            
        }
    }
    
    func fetchedResultsControllerWillChangeContent( controller: FetchedEBookFileController ) {
        //        tableView?.beginUpdates()
    }
    
    func fetchedResultsControllerDidChangeContent( controller: FetchedEBookFileController ) {
        //        tableView?.endUpdates()
    }
    
    func fetchedResultsController(controller: FetchedEBookFileController,
                                  didChangeObject change: FetchedEBookFileChange) {
        switch change {
        case let .Insert(object, indexPath):
//            tableView?.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            break
            
        case let .Delete(_, indexPath):
//            tableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            break
            
        case let .Move(_, fromIndexPath, toIndexPath):
//            tableView?.moveRowAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
            break
            
        case let .Update(_, indexPath):
//            tableView?.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            break
        }
    }
    
    func fetchedResultsController( controller: FetchedEBookFileController,
                                   didChangeSection change: FetchedEBookFileSectionChange ) {
        switch change {
        case .Insert(_, _):
            // tableVC.tableView.insertSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
            break
            
        case .Delete(_, _):
            // tableVC.tableView.deleteSections(NSIndexSet(index: index), withRowAnimation: .Automatic)
            break
        }
    }
}

