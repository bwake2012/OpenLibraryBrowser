//
//  OLDataSource.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/28/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

protocol OLDataSource {

    func numberOfSections() -> Int
    func numberOfRowsInSection( _ section: Int ) -> Int
//    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLManagedObject?

    @discardableResult func displayToCell( _ cell: OLTableViewCell, indexPath: IndexPath ) -> OLManagedObject?
    func updateUI() -> Void

    func clearQuery() -> Void
}
