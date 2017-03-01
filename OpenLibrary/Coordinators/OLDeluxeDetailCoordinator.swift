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
    func numberOfRowsInSection( _ section: Int ) -> Int
    func objectAtIndexPath( _ indexPath: IndexPath ) -> DeluxeData?
    func didSelectRowAtIndexPath( _ indexPath: IndexPath )
    
    func displayToTableViewCell( _ tableView: UITableView, indexPath: IndexPath ) -> UITableViewCell
    
    func cancelOperations() -> Void
    
    func installPictureCoordinator( _ destVC: OLPictureViewController ) -> Void
    func installBookDownloadCoordinator( _ destVC: OLBookDownloadViewController ) -> Void
}

