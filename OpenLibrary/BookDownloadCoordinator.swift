//
//  BookDownloadCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 18/6/2016.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData
import SafariServices

import BNRCoreDataStack
import PSOperations

let kEBookFileCache = "eBookXMLFileCache"

let kFileTypeMOBI     = "MobiPocket"
let kFileTypeEPUB     = "ePub"
let kFileTypeDjVu     = "DjVu"
let kFileTypeTextPDF  = "Text PDF"
let kFileTypeDjVuText = "DjVuTXT"

class BookDownloadCoordinator: OLQueryCoordinator, FetchedResultsControllerDelegate, UIDocumentInteractionControllerDelegate {
    
    weak var downloadVC: OLBookDownloadViewController?
    
    private var heading: String
    private var bookURL: NSURL
    private var eBookKey = ""

    private var xmlFileDownloadOperation: InternetArchiveEbookInfoGetOperation?
    private var bookDownloadOperation: BookGetOperation?
    
    private var docInteractionController: UIDocumentInteractionController?
    
    private lazy var cachesFolder =
        try! NSFileManager.defaultManager().URLForDirectory(
                        .CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true
                    )

    
    typealias FetchedEBookFileController    = FetchedResultsController< OLEBookFile >
    typealias FetchedEBookFileChange        = FetchedResultsObjectChange< OLEBookFile >
    typealias FetchedEBookFileSectionChange = FetchedResultsSectionChange< OLEBookFile >
    
    private lazy var fetchedEBookFileController: FetchedEBookFileController = {
        
        let fetchRequest = NSFetchRequest( entityName: OLEBookFile.entityName )
        
//        let secondsPerDay = NSTimeInterval( 24 * 60 * 60 )
//        let today = NSDate()
//        let lastWeek = today.dateByAddingTimeInterval( -7 * secondsPerDay )
        
        fetchRequest.predicate = NSPredicate( format: "eBookKey==%@", "\(self.eBookKey)" )
        
        fetchRequest.sortDescriptors =
            [
                NSSortDescriptor( key: "format", ascending: true ),
                NSSortDescriptor( key: "name", ascending: true )
            ]
        fetchRequest.fetchBatchSize = 100
        
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
        heading: String,
        bookURL: NSURL,
        downloadVC: OLBookDownloadViewController
    ) {
    
        self.heading = heading
        self.bookURL = bookURL
        self.eBookKey = bookURL.lastPathComponent ?? ""
    
        self.downloadVC = downloadVC

        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: downloadVC )
    }
    
    func updateUI() {
        
        if let downloadVC = downloadVC {
            
            downloadVC.updateHeading( heading )
        }
        
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
    
    // MARK: utility
    
    func readOnline() {
        
        if let downloadVC = downloadVC {
            showLinkedWebSite( downloadVC, url: bookURL )
        }
    }
    
    func readMOBI( button: UIButton ) {
        
        downloadAndOpenBook( button, bookType: kFileTypeMOBI )
    }
    
    func readEPUB( button: UIButton ) {
        
        downloadAndOpenBook( button, bookType: kFileTypeEPUB )
    }
    
    func readTextPDF( button: UIButton ) {
        
        downloadAndOpenBook( button, bookType: kFileTypeTextPDF )
    }
    
    func readText( button: UIButton ) {
        
        downloadAndOpenBook( button, bookType: kFileTypeDjVuText )
    }
    
    func readDjVu( button: UIButton ) {
        
        downloadAndOpenBook( button, bookType: kFileTypeDjVu )
    }
    
    func sendToKindle( button: UIButton ) {
        
        if let downloadVC = downloadVC {

            if let amazonURL = assembleKindleURL( eBookKey ) {
            
                showLinkedWebSite( downloadVC, url: amazonURL )
            }
        }
    }
    
    func downloadAndOpenBook( sourceView: UIView, bookType: String ) {

        // don't try to open a book if a book download is in progress
        if nil == bookDownloadOperation {
            
            if nil != downloadVC {

                if let remoteURL = assembleRemoteURL( eBookKey, fileFormat: bookType ),
                       localPath = assembleLocalPath( eBookKey, fileFormat: bookType ) {
                
                    downloadAndOpenBook( sourceView, localPath: localPath, remoteURL: remoteURL, fileFormat: bookType )
                }
            }
        }
    }
    
    func downloadAndOpenBook( sourceView: UIView, localPath: String, remoteURL: NSURL, fileFormat: String ) {
        
        let localURL = NSURL( fileURLWithPath: localPath )

        // don't download a book if we already have a copy
        if NSFileManager.defaultManager().fileExistsAtPath( localPath ) {
            
            openBook( sourceView, url: localURL, fileFormat: fileFormat )
            
        } else {

            print( "local:\(localURL.absoluteString)\nremote:\(remoteURL.absoluteString)" )
            
            bookDownloadOperation =
                BookGetOperation( cacheBookURL: localURL, remoteBookURL: remoteURL ) {
                    
                        [weak self] in
                        
                        if let strongSelf = self {
                            
                            dispatch_async( dispatch_get_main_queue() ) {
                                
                                strongSelf.openBook( sourceView, url: localURL, fileFormat: fileFormat )
                            }
                        }
                    }
            
            bookDownloadOperation!.userInitiated = true
            operationQueue.addOperation( bookDownloadOperation! )
        }
    }
    
    func findFileName( fileFormat: String ) -> String? {
    
        if let fetchedObjects = fetchedEBookFileController.fetchedObjects {
            
            for file in fetchedObjects {
                
                if fileFormat == file.format {
                    
                    return file.name
                }
            }
        }
        
        return nil
    }

    func assembleRemoteURL( eBookKey: String, fileFormat: String ) -> NSURL? {
        
        var url: NSURL?
        
        if let rootURL = bookURL.host, components = bookURL.pathComponents {
            
            var fileName = ""
            
            switch fileFormat {
            case kFileTypeEPUB:
                fileName = eBookKey + ".epub"
            case kFileTypeMOBI:
                fileName = eBookKey + ".mobi"
            default:
                guard let name = findFileName( fileFormat ) else { return nil }
                
                fileName = name
                break
            }
            
            if !fileName.isEmpty {
                var newComponents = [String]()
                for component in components {
                    
                    if "stream" == component {
                        
                        newComponents.append( "download" )
                        
                    } else {
                        
                        newComponents.append( component )
                    }
                }
                newComponents = newComponents.filter { (x) -> Bool in !x.isEmpty && "/" != x }
                
                let path = newComponents.joinWithSeparator( "/" )
                let completePath = "https://" + rootURL + "/" + path + "/" + fileName
                if let newURL = NSURL( string: completePath ) {
                    
                    url = newURL
                }
            }
        }
        
        return url
    }
    
    func assembleLocalPath( eBookKey: String, fileFormat: String ) -> String? {
    
        var path: String?
        
        if let rootPath = cachesFolder.path {

            var fileName = ""

            switch fileFormat {
            case kFileTypeEPUB:
                fileName = eBookKey + ".epub"
            case kFileTypeMOBI:
                fileName = eBookKey + ".mobi"
            default:
                guard let name = findFileName( fileFormat ) else { return nil }
                
                fileName = name
                break
            }
            
            if !fileName.isEmpty {

                path = rootPath + "/" + fileName
            }
        }

        return path
    }
    
    func openBook( sourceView: UIView, url: NSURL, fileFormat: String ) {
        
        if let downloadVC = self.downloadVC {
            
            self.docInteractionController = UIDocumentInteractionController( URL: url )
            if let docInteractionController = self.docInteractionController {

                docInteractionController.delegate = self
                
                let success = docInteractionController.presentOpenInMenuFromRect(
                                        CGRectZero, inView: downloadVC.view, animated: true
                                    )
                if !success {
                    
                    let alert =
                            UIAlertController(
                                    title: self.heading,
                                    message: "Could not find an application to open your \(fileFormat) book.",
                                    preferredStyle: .Alert
                                )
                    alert.addAction( UIAlertAction( title: "OK", style: .Default, handler: nil ) )
                    
                    downloadVC.presentViewController( alert, animated: true, completion: nil )
                }
            }
            self.bookDownloadOperation = nil
        }
    }
    
    func assembleKindleURL( eBookKey: String ) -> NSURL? {
        
        let urlString =
            "https://www.amazon.com/gp/digital/fiona/web-to-kindle?" +
                "clientid=IA" + "&itemid=\(eBookKey)" + "&docid=\(eBookKey)"
        
        return NSURL( string: urlString )
    }

    func newQuery( eBookKey: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) -> Void {
        
        if nil == xmlFileDownloadOperation {
            xmlFileDownloadOperation =
                InternetArchiveEbookInfoGetOperation(
                    eBookKey: eBookKey,
                    coreDataStack: coreDataStack
                ) {
                    
                    self.xmlFileDownloadOperation = nil
                }
            
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
            
        } else {
            
            
            if let fetchedObjects = fetchedEBookFileController.fetchedObjects {
                
                for file in fetchedObjects {
                    
                    downloadVC?.updateUI( file )
                        
                }
            }
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
        case .Insert(_, _):
//            tableView?.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            break
            
        case .Delete(_, _):
//            tableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            break
            
        case .Move(_, _, _):
//            tableView?.moveRowAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
            break
            
        case .Update(_, _):
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

extension BookDownloadCoordinator: SFSafariViewControllerDelegate {
    
    func showLinkedWebSite( vc: UIViewController, url: NSURL? ) {
        
        if let url = url {
            let webVC = SFSafariViewController( URL: url )
            webVC.delegate = self
            vc.presentViewController( webVC, animated: true, completion: nil )
        }
    }
    
    // MARK: SFSafariViewControllerDelegate
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        
        controller.dismissViewControllerAnimated( true, completion: nil )
    }
    
}
