//
//  AuthorDeluxeDetailCoordinator.swift
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

class AuthorDeluxeDetailCoordinator: OLQueryCoordinator, OLDataSource, SFSafariViewControllerDelegate {
    
    weak var authorDeluxeDetailVC: OLAuthorDeluxeDetailTableViewController?

    var authorDetail: OLAuthorDetail
    
    init(
            operationQueue: OperationQueue,
            coreDataStack: CoreDataStack,
            authorDetail: OLAuthorDetail,
            authorDeluxeDetailVC: OLAuthorDeluxeDetailTableViewController
        ) {
        
        self.authorDetail = authorDetail
        self.authorDeluxeDetailVC = authorDeluxeDetailVC

        super.init( operationQueue: operationQueue, coreDataStack: coreDataStack )
        
    }
    
    // MARK: OLDataSource
    func numberOfSections() -> Int {
        
        print( "sections: \(authorDetail.deluxeData.count)" )
        return authorDetail.deluxeData.count
    }
    
    func numberOfRowsInSection( section: Int ) -> Int {
        
        print( "section:\(section) rows:\(authorDetail.deluxeData[section].count)" )
        return section < 0 || section >= authorDetail.deluxeData.count ? 0 : authorDetail.deluxeData[section].count
    }
    
    func objectAtIndexPath( indexPath: NSIndexPath ) -> DeluxeData? {
        
        return indexPath.section < 0 || indexPath.section >= authorDetail.deluxeData.count || indexPath.row < 0 || indexPath.row >= authorDetail.deluxeData[indexPath.section].count ? nil : authorDetail.deluxeData[indexPath.section][indexPath.row]
    }
    
    func didSelectRowAtIndexPath( indexPath: NSIndexPath ) {
    
        guard let vc = authorDeluxeDetailVC else { return }
        guard let obj = objectAtIndexPath( indexPath ) else { return }
        
        if .link == obj.type {

            showLinkedWebSite( vc, url: NSURL( string: obj.value ) )
        }
    }
    
    func displayToTableViewCell( tableView: UITableView, indexPath: NSIndexPath ) -> UITableViewCell {
        
        print( "display section:\(indexPath.section) rows:\(indexPath.row)" )

        var cell: UITableViewCell?
        if let object = objectAtIndexPath( indexPath ) {
            
            switch object.type {
            case .unknown:
                assert( false )
                break
            case .header:
                if let headerCell = tableView.dequeueReusableCellWithIdentifier( object.type.rawValue ) as? DeluxeDetailHeaderTableViewCell {
                    
                    headerCell.configure( authorDetail )
                    cell = headerCell
                }
                break
            case .inline:
                if let inlineCell = tableView.dequeueReusableCellWithIdentifier( object.type.rawValue ) as? DeluxeDetailInlineTableViewCell {
                    
                    inlineCell.configure( object )
                    cell = inlineCell
                }
                break
            case .block:
                if let blockCell = tableView.dequeueReusableCellWithIdentifier( object.type.rawValue ) as? DeluxeDetailBlockTableViewCell {
                    
                    blockCell.configure( object )
                    cell = blockCell
                }
                break
            case .link:
                if let linkCell = tableView.dequeueReusableCellWithIdentifier( object.type.rawValue ) as? DeluxeDetailLinkTableViewCell {
                    
                    linkCell.configure( object )
                    cell = linkCell
                }
            case .authorImage:
                if let imageCell = tableView.dequeueReusableCellWithIdentifier( object.type.rawValue ) as? DeluxedDetailImageTableViewCell {
                    
                    if let url = NSURL( string: object.value ) {
                        if !imageCell.displayFromURL( url ) {
                            
                            let imageGetOperation =
                                ImageGetOperation( stringID: object.caption, imageKeyName: "ID", localURL: url, size: "M", type: "a" ) {
                                    
                                    [weak self] in
                                    
                                    guard let strongSelf = self else { return }
                                    guard let vc = strongSelf.authorDeluxeDetailVC else { return }
                                        
                                    dispatch_async( dispatch_get_main_queue() ) {
                                        
                                        vc.tableView.reloadRowsAtIndexPaths(
                                            [indexPath], withRowAnimation: .Automatic
                                        )
                                    }
                            }
                            
                            imageGetOperation.userInitiated = true
                            operationQueue.addOperation( imageGetOperation )
                        }
                    }
                    cell = imageCell
                }

            default:
                assert( false )
            }
        }
        
        return cell!
    }
    

    // MARK: utility
    
    // MARK: query coordinator installation
    
    func installAuthorPictureCoordinator( destVC: OLPictureViewController ) {
        
        guard let deluxeVC = authorDeluxeDetailVC else { return }
        
        guard let indexPath = deluxeVC.tableView.indexPathForSelectedRow else { return }
        
        destVC.queryCoordinator =
            AuthorPictureViewCoordinator(
                    operationQueue: operationQueue,
                    coreDataStack: coreDataStack,
                    authorDetail: authorDetail,
                    pictureIndex: indexPath.section == 0 ? 0 : indexPath.row + 1,
                    pictureVC: destVC
                )
    }
    
    // MARK: SFSafariViewControllerDelegate
    
    func showLinkedWebSite( vc: UIViewController, url: NSURL? ) {
        
        if let url = url {
            let webVC = SFSafariViewController( URL: url )
            webVC.delegate = self
            vc.presentViewController( webVC, animated: true, completion: nil )
        }
    }
    
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        
        controller.dismissViewControllerAnimated( true, completion: nil )
    }

}
