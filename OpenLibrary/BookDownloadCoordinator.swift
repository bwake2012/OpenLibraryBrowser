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

class BookDownloadCoordinator: OLQueryCoordinator, NSFetchedResultsControllerDelegate, UIDocumentInteractionControllerDelegate {
    
    weak var downloadVC: OLBookDownloadViewController?
    
    fileprivate var heading: String
    fileprivate var bookURL: URL
    fileprivate var eBookKey = ""

    fileprivate var xmlFileDownloadOperation: InternetArchiveEbookInfoGetOperation?
    fileprivate var bookDownloadOperation: BookGetOperation?
    
    fileprivate var docInteractionController: UIDocumentInteractionController?
    
    fileprivate lazy var cachesFolder =
        try! FileManager.default.url(
                        for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true
                    )

    
    typealias FetchedEBookFileController    = NSFetchedResultsController< OLEBookFile >
    typealias FetchedEBookFileChange        = FetchedResultsObjectChange< OLEBookFile >
    typealias FetchedEBookFileSectionChange = FetchedResultsSectionChange< OLEBookFile >
    
    fileprivate lazy var fetchedEBookFileController: FetchedEBookFileController = {
        
        let fetchRequest = OLEBookFile.buildFetchRequest()

//        let secondsPerDay = NSTimeInterval( 24 * 60 * 60 )
//        let today = NSDate()
//        let lastWeek = today.dateByAddingTimeInterval( -7 * secondsPerDay )
        
        fetchRequest.predicate = NSPredicate( format: "eBookKey==%@", self.eBookKey )
        
        fetchRequest.sortDescriptors =
            [
                NSSortDescriptor( key: "format", ascending: true ),
                NSSortDescriptor( key: "name", ascending: true )
            ]
        fetchRequest.fetchBatchSize = 100
        
        let frc = FetchedEBookFileController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.dataStack.mainQueueContext,
            sectionNameKeyPath: nil,
            cacheName: nil ) // kEBookFileCache )
        
        frc.delegate = self
        return frc
    }()
    
    init(
        operationQueue: PSOperationQueue,
        dataStack: OLDataStack,
        heading: String,
        bookURL: URL,
        downloadVC: OLBookDownloadViewController
    ) {
    
        self.heading = heading
        self.bookURL = bookURL
        self.eBookKey = bookURL.lastPathComponent
    
        self.downloadVC = downloadVC

        super.init( operationQueue: operationQueue, dataStack: dataStack, viewController: downloadVC )
    }
    
    func updateUI() {
        
        if let downloadVC = downloadVC {
            
            downloadVC.updateHeading( heading )
        }
        
        if nil != downloadVC {
            do {
//                NSFetchedResultsController< OLEBookFile >.deleteCache( withName: kEBookFileCache )
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
    
    func readMOBI( _ button: UIButton ) {
        
        downloadAndOpenBook( button, bookType: kFileTypeMOBI )
    }
    
    func readEPUB( _ button: UIButton ) {
        
        downloadAndOpenBook( button, bookType: kFileTypeEPUB )
    }
    
    func readTextPDF( _ button: UIButton ) {
        
        downloadAndOpenBook( button, bookType: kFileTypeTextPDF )
    }
    
    func readText( _ button: UIButton ) {
        
        downloadAndOpenBook( button, bookType: kFileTypeDjVuText )
    }
    
    func readDjVu( _ button: UIButton ) {
        
        downloadAndOpenBook( button, bookType: kFileTypeDjVu )
    }
    
    func sendToKindle( _ button: UIButton ) {
        
        if let downloadVC = downloadVC {

            if let amazonURL = assembleKindleURL( eBookKey ) {
            
                showLinkedWebSite( downloadVC, url: amazonURL )
            }
        }
    }
    
    func downloadAndOpenBook( _ sourceView: UIView, bookType: String ) {

        // don't try to open a book if a book download is in progress
        if nil == bookDownloadOperation {
            
            if nil != downloadVC {

                if let remoteURL = assembleRemoteURL( eBookKey, fileFormat: bookType ),
                       let localPath = assembleLocalPath( eBookKey, fileFormat: bookType ) {
                
                    downloadAndOpenBook( sourceView, localPath: localPath, remoteURL: remoteURL, fileFormat: bookType )
                }
            }
        }
    }
    
    func downloadAndOpenBook( _ sourceView: UIView, localPath: String, remoteURL: URL, fileFormat: String ) {
        
        let localURL = URL( fileURLWithPath: localPath )

        // don't download a book if we already have a copy
        if FileManager.default.fileExists( atPath: localPath ) {
            
            openBook( sourceView, url: localURL, fileFormat: fileFormat )
            
        } else {

            print( "local:\(localURL.absoluteString)\nremote:\(remoteURL.absoluteString)" )
            
            bookDownloadOperation =
                BookGetOperation( cacheBookURL: localURL, remoteBookURL: remoteURL ) {
                    
                        [weak self] in
                        
                        DispatchQueue.main.async {
                                
                            if let strongSelf = self {
                                
                                strongSelf.openBook( sourceView, url: localURL, fileFormat: fileFormat )
                            }
                        }
                    }
            
            bookDownloadOperation!.userInitiated = true
            operationQueue.addOperation( bookDownloadOperation! )
        }
    }
    
    func findFileName( _ fileFormat: String ) -> String? {
    
        if let fetchedObjects = fetchedEBookFileController.fetchedObjects {
            
            for file in fetchedObjects {
                
                if fileFormat == file.format {
                    
                    return file.name
                }
            }
        }
        
        return nil
    }

    func assembleRemoteURL( _ eBookKey: String, fileFormat: String ) -> URL? {
        
        var url: URL?
        let components = bookURL.pathComponents
        if let rootURL = bookURL.host {
            
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
                
                let path = newComponents.joined( separator: "/" )
                let completePath = "https://" + rootURL + "/" + path + "/" + fileName
                if let newURL = URL( string: completePath ) {
                    
                    url = newURL
                }
            }
        }
        
        return url
    }
    
    func assembleLocalPath( _ eBookKey: String, fileFormat: String ) -> String? {
    
        var path: String?
        
        let rootPath = cachesFolder.path

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

        return path
    }
    
    func openBook( _ sourceView: UIView, url: URL, fileFormat: String ) {
        
        if let downloadVC = self.downloadVC {
            
            self.docInteractionController = UIDocumentInteractionController( url: url )
            if let docInteractionController = self.docInteractionController {

                docInteractionController.delegate = self
                
                let success = docInteractionController.presentOpenInMenu(
                                        from: CGRect.zero, in: downloadVC.view, animated: true
                                    )
                if !success {
                    
                    let alert =
                            UIAlertController(
                                    title: self.heading,
                                    message: "Could not find an application to open your \(fileFormat) book.",
                                    preferredStyle: .alert
                                )
                    alert.addAction( UIAlertAction( title: "OK", style: .default, handler: nil ) )
                    
                    downloadVC.present( alert, animated: true, completion: nil )
                }
            }
            self.bookDownloadOperation = nil
        }
    }
    
    func assembleKindleURL( _ eBookKey: String ) -> URL? {
        
        let urlString =
            "https://www.amazon.com/gp/digital/fiona/web-to-kindle?" +
                "clientid=IA" + "&itemid=\(eBookKey)" + "&docid=\(eBookKey)"
        
        return URL( string: urlString )
    }

    func newQuery( _ eBookKey: String, userInitiated: Bool, refreshControl: UIRefreshControl? ) -> Void {
        
        if nil == xmlFileDownloadOperation {
            xmlFileDownloadOperation =
                InternetArchiveEbookInfoGetOperation(
                    eBookKey: eBookKey,
                    dataStack: dataStack
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

    func objectAtIndexPath( _ indexPath: IndexPath ) -> OLEBookFile? {
        
        guard let sections = fetchedEBookFileController.sections else {
            assertionFailure("Sections missing")
            return nil
        }
        
        let section = sections[indexPath.section]
        guard let itemsInSection = section.objects as? [OLEBookFile] else {
            fatalError("Missing items")
        }
        
        if indexPath.row >= itemsInSection.count {
            return nil
        } else {
            return itemsInSection[indexPath.row]
        }
    }
    
    // MARK: FetchedResultsControllerDelegate
    
    func fetchedResultsControllerDidPerformFetch(_ controller: FetchedEBookFileController) {
        
        if 0 == controller.sections?[0].numberOfObjects ?? 0 {
            
            newQuery( eBookKey, userInitiated: true, refreshControl: nil )
            
        } else {
            
            
            if let fetchedObjects = fetchedEBookFileController.fetchedObjects {
                
                for file in fetchedObjects {
                    
                    downloadVC?.updateUI( file )
                        
                }
            }
        }
    }
    
}

extension BookDownloadCoordinator: SFSafariViewControllerDelegate {
    
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
