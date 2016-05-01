//
//  OLDataSource.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/28/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

protocol OLDataSource {
    
    associatedtype OLObject
//    associatedtype OLTableViewCell
    
    func numberOfSections() -> Int
    func numberOfRowsInSection( section: Int ) -> Int
    func objectAtIndexPath( indexPath: NSIndexPath ) -> OLObject?
//    func displayToCell( cell: OLTableViewCell, indexPath: NSIndexPath ) -> OLObject?

}