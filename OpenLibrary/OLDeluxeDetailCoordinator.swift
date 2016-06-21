//
//  OLDeluxeDetailCoordinator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 5/3/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation
import UIKit

protocol OLDeluxeDetailCoordinator {

    func numberOfSections() -> Int
    func numberOfRowsInSection( section: Int ) -> Int
    func objectAtIndexPath( indexPath: NSIndexPath ) -> DeluxeData?
    func didSelectRowAtIndexPath( indexPath: NSIndexPath )
    
    func displayToTableViewCell( tableView: UITableView, indexPath: NSIndexPath ) -> UITableViewCell
    
    func cancelOperations() -> Void
    
    func installPictureCoordinator( destVC: OLPictureViewController ) -> Void
    func installBookDownloadCoordinator( destVC: OLBookDownloadViewController ) -> Void
}

