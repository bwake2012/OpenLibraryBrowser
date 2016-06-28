//
//  DeluxeDetailCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/22/2016.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import CoreData
import SafariServices

import BNRCoreDataStack

// let kAuthorDeluxeDetailCache = "authorDeluxeDetail"

class DeluxeDetailCoordinator: OLQueryCoordinator, OLDeluxeDetailCoordinator, SFSafariViewControllerDelegate {
    
    weak var deluxeDetailVC: OLDeluxeDetailTableViewController?

    var heading: String
    var deluxeData: [[DeluxeData]]
    var imageType: String
    
    var imageGetOperation: ImageGetOperation?
    
    init(
            operationQueue: OperationQueue,
            coreDataStack: CoreDataStack,
            heading: String,
            deluxeData: [[DeluxeData]],
            imageType: String,
            deluxeDetailVC: OLDeluxeDetailTableViewController
        ) {
        
        self.heading = heading
        self.deluxeData = deluxeData
        self.imageType = imageType
        self.deluxeDetailVC = deluxeDetailVC

        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack, viewController: deluxeDetailVC )
        
    }
    
    // MARK: OLDataSource
    func numberOfSections() -> Int {
        
//        print( "sections: \(deluxeData.count)" )
        return deluxeData.count
    }
    
    func numberOfRowsInSection( section: Int ) -> Int {
        
//        print( "section:\(section) rows:\(deluxeData[section].count)" )
        return section < 0 || section >= deluxeData.count ? 0 : deluxeData[section].count
    }
    
    func objectAtIndexPath( indexPath: NSIndexPath ) -> DeluxeData? {
        
        guard indexPath.section >= 0 else { return nil }
        guard indexPath.section < deluxeData.count else { return nil }
        guard indexPath.row >= 0 else { return nil }
        guard indexPath.row < deluxeData[indexPath.section].count else { return nil }
        
        return deluxeData[indexPath.section][indexPath.row]
    }
    
    func didSelectRowAtIndexPath( indexPath: NSIndexPath ) {
    
        guard let vc = deluxeDetailVC else { return }
        guard let obj = objectAtIndexPath( indexPath ) else { return }
        
        if .link == obj.type {

            showLinkedWebSite( vc, url: NSURL( string: obj.value ) )
        
        } else if .imageAuthor == obj.type || .imageBook == obj.type {
            
            vc.performSegueWithIdentifier( "zoomDeluxeDetailImage", sender: self )
            
        } else if .downloadBook == obj.type {
            
            vc.performSegueWithIdentifier( obj.type.reuseIdentifier, sender: self )
            
        }
    }
    
    func displayToTableViewCell( tableView: UITableView, indexPath: NSIndexPath ) -> UITableViewCell {
        
        var cell: UITableViewCell?
        if let object = objectAtIndexPath( indexPath ) {
            
//            print( "display section:\(indexPath.section) row:\(indexPath.row) \(object.type.rawValue)" )
            
            switch object.type {
            case .unknown:
                assert( false )
                break
                
            case .heading,
                 .subheading,
                 .body,
                 .inline,
                 .block,
                 .link,
                 .html:
                if let headerCell = tableView.dequeueReusableCellWithIdentifier( object.type.reuseIdentifier ) as? DeluxeDetailTableViewCell {
                    
                    headerCell.configure( object )
                    cell = headerCell
                }
                break
                
            case .imageAuthor, .imageBook:
                if let imageCell = tableView.dequeueReusableCellWithIdentifier( object.type.reuseIdentifier ) as? DeluxeDetailImageTableViewCell {
                    
                    if let url = NSURL( string: object.value ) {
                        if !imageCell.displayFromURL( url ) {
                            
                            if nil == imageGetOperation {
                                
                                let imageType = .imageAuthor == object.type ? "a" : "b"
                                
                                imageGetOperation =
                                    ImageGetOperation( stringID: object.caption, imageKeyName: "ID", localURL: url, size: "M", type: imageType ) {
                                        
                                        [weak self] in
                                        
                                        guard let strongSelf = self else { return }
                                        guard let vc = strongSelf.deluxeDetailVC else { return }
                                        
                                        dispatch_async( dispatch_get_main_queue() ) {
                                            
                                            vc.tableView.reloadRowsAtIndexPaths(
                                                [indexPath], withRowAnimation: .Automatic
                                            )
                                        }
                                        
                                        strongSelf.imageGetOperation = nil
                                }
                                
                                imageGetOperation!.userInitiated = true
                                operationQueue.addOperation( imageGetOperation! )
                            }
                        }
                    }
                    cell = imageCell
                }
            case .downloadBook:
                if let headerCell = tableView.dequeueReusableCellWithIdentifier( object.type.reuseIdentifier ) as? DeluxeDetailTableViewCell {
                    
                    headerCell.configure( object )
                    cell = headerCell
                }
                break
                
            }
        }
        
        return cell!
    }
    
    func cancelOperations() {
        
        imageGetOperation?.cancel()
    }

    // MARK: utility

    // MARK: query coordinator installation
    
    func installPictureCoordinator( destVC: OLPictureViewController ) -> Void {
        
        guard let deluxeVC = deluxeDetailVC else { return }
        
        guard let indexPath = deluxeVC.tableView.indexPathForSelectedRow else { return }
        
        guard let object = objectAtIndexPath( indexPath ) else { return }
        
        guard let largeImageURL = NSURL( string: object.extraValue ) else { return }
        
        destVC.queryCoordinator =
            PictureViewCoordinator(
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    localURL: largeImageURL,
                    imageID: Int( object.caption )!,
                    pictureType: imageType,
                    pictureVC: destVC
                )
    }
    
    func installBookDownloadCoordinator( destVC: OLBookDownloadViewController ) -> Void {
        
        guard let deluxeVC = deluxeDetailVC else { return }
        
        guard let indexPath = deluxeVC.tableView.indexPathForSelectedRow else { return }
        
        guard let object = objectAtIndexPath( indexPath ) else { return }
        
        guard let bookURL = NSURL( string: object.extraValue ) else { return }

        destVC.queryCoordinator =
            BookDownloadCoordinator(
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    heading: heading,
                    bookURL: bookURL,
                    downloadVC: destVC
                )
    }
    
    
    // MARK: Safari View Controller
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
