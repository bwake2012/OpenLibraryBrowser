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
import PSOperations

// let kAuthorDeluxeDetailCache = "authorDeluxeDetail"

class DeluxeDetailCoordinator: OLQueryCoordinator, OLDeluxeDetailCoordinator {
    
    weak var deluxeDetailVC: OLDeluxeDetailTableViewController?

    var heading: String
    var deluxeData: [[DeluxeData]]
    var imageType: String
    
    var imageGetOperation: ImageGetOperation?
    
    init(
            operationQueue: PSOperationQueue,
            coreDataStack: OLDataStack,
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
    
    func numberOfRowsInSection( _ section: Int ) -> Int {
        
//        print( "section:\(section) rows:\(deluxeData[section].count)" )
        return section < 0 || section >= deluxeData.count ? 0 : deluxeData[section].count
    }
    
    func objectAtIndexPath( _ indexPath: IndexPath ) -> DeluxeData? {
        
        let section = indexPath.section
        assert( section >= 0 && section < deluxeData.count )
        guard section >= 0 else { return nil }
        guard section < deluxeData.count else { return nil }
        
        let sectionData = deluxeData[section]
        
        let row = indexPath.row
        assert( row >= 0 && row < sectionData.count )
        guard row >= 0 else { return nil }
        guard row < sectionData.count else { return nil }
        
        let rowData = sectionData[row]
        
        return rowData
    }
    
    func didSelectRowAtIndexPath( _ indexPath: IndexPath ) {
    
        guard let vc = deluxeDetailVC else { return }
        guard let obj = objectAtIndexPath( indexPath ) else { return }
        
        if .link == obj.type {
            
            var urlComponents = URLComponents( string: obj.value )
            
            if nil == urlComponents {
                
                urlComponents = URLComponents()

                var hostPlusPath = obj.value

                var scheme = ""
                if hostPlusPath.hasPrefix( "http://" ) {
                    
                    hostPlusPath = hostPlusPath.substring( from: hostPlusPath.characters.index(hostPlusPath.startIndex, offsetBy: 7) )
                    scheme = "http"
                    
                } else if hostPlusPath.hasPrefix( "https://" ) {
                    
                    hostPlusPath = hostPlusPath.substring( from: hostPlusPath.characters.index(hostPlusPath.startIndex, offsetBy: 8) )
                    scheme = "https"
                    
                } else {
                    
                    hostPlusPath = ""
                }
                
                if !hostPlusPath.isEmpty {
                    
                    var host: String?
                    var path = ""
                    for index in hostPlusPath.characters.indices {
                        
                        if "/" == hostPlusPath[index] {
                            
                            host = hostPlusPath.substring( to: index )
                            path = hostPlusPath.substring( from: index )
                            break
                        }
                    }
                    if path.isEmpty {
                        
                        path = hostPlusPath
                    }
                    
                    urlComponents?.scheme = scheme
                    urlComponents?.host = host
                    urlComponents?.path = path
                }
            }
            if let url = urlComponents?.url {
                
                showLinkedWebSite( vc, url: url )
            }
        
        } else if .imageAuthor == obj.type || .imageBook == obj.type {
            
            vc.performSegue( withIdentifier: "zoomLargeImage", sender: self )
            
        } else if .downloadBook == obj.type {
            
            vc.performSegue( withIdentifier: obj.type.reuseIdentifier, sender: self )
            
        }
    }
    
    func displayToTableViewCell( _ tableView: UITableView, indexPath: IndexPath ) -> UITableViewCell {
        
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
                if let headerCell = tableView.dequeueReusableCell( withIdentifier: object.type.reuseIdentifier ) as? DeluxeDetailTableViewCell {
                    
                    headerCell.configure( object )
                    cell = headerCell
                }
                break
                
            case .imageAuthor, .imageBook:
                if let imageCell = tableView.dequeueReusableCell( withIdentifier: object.type.reuseIdentifier ) as? DeluxeDetailImageTableViewCell {
                    
                    if let url = URL( string: object.value ) {
                        if !imageCell.displayFromURL( url ) {
                            
                            if nil == imageGetOperation {
                                
                                let imageType = .imageAuthor == object.type ? "a" : "b"
                                
                                imageGetOperation =
                                    ImageGetOperation( stringID: object.caption, imageKeyName: "ID", localURL: url, size: "M", type: imageType ) {
                                        
                                        [weak self] in
                                        
                                        DispatchQueue.main.async {
                                            
                                            guard let strongSelf = self else { return }
                                            guard let vc = strongSelf.deluxeDetailVC else { return }
                                            
                                            vc.tableView.reloadRows(
                                                at: [indexPath], with: .automatic
                                            )
                                        }
                                        
                                        self?.imageGetOperation = nil
                                }
                                
                                imageGetOperation!.userInitiated = true
                                operationQueue.addOperation( imageGetOperation! )
                            }
                        }
                    }
                    cell = imageCell
                }
            case .downloadBook, .borrowBook, .buyBook:
                if let headerCell = tableView.dequeueReusableCell( withIdentifier: object.type.reuseIdentifier ) as? DeluxeDetailTableViewCell {
                    
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
    
    func installPictureCoordinator( _ destVC: OLPictureViewController ) -> Void {
        
        guard let deluxeVC = deluxeDetailVC else { return }
        
        guard let indexPath = deluxeVC.tableView.indexPathForSelectedRow else { return }
        
        guard let object = objectAtIndexPath( indexPath ) else { return }
        
        guard let largeImageURL = URL( string: object.extraValue ) else { return }
        
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
    
    func installBookDownloadCoordinator( _ destVC: OLBookDownloadViewController ) -> Void {
        
        guard let deluxeVC = deluxeDetailVC else { return }
        
        guard let indexPath = deluxeVC.tableView.indexPathForSelectedRow else { return }
        
        guard let object = objectAtIndexPath( indexPath ) else { return }
        
        guard let bookURL = URL( string: object.extraValue ) else { return }

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
}

extension DeluxeDetailCoordinator: SFSafariViewControllerDelegate {
    
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
