//
//  OLTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/19/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class OLTableViewCell: UITableViewCell {

    var currentImageURL: NSURL?
    
    @IBOutlet weak var cellImage: UIImageView!

    func transitionSourceRectView() -> UIImageView? {
        
        return cellImage
    }
    
    func displayImage( localURL: NSURL ) -> Bool {
        
        guard nil == currentImageURL || localURL == currentImageURL else { return true }
        
        if cellImage.displayFromURL( localURL ) {
            currentImageURL = localURL
            return true
        }
        
        return false
    }
    
    func clearCurrentImage() -> Void {
    
        currentImageURL = nil
        cellImage.image = UIImage( named: "961-book-32.png" )
    }
    
    func configure( tableView: UITableView, indexPath: NSIndexPath, data: OLManagedObject? ) -> Void {
        
    }
}

protocol OLConfigureCell {
    
    associatedtype ObjectType
    
    func configureCell( object: ObjectType )
}



