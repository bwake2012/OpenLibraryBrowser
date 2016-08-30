//
//  OLTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/19/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class OLTableViewCell: UITableViewCell {

    var currentImageFile: String?
    
    @IBOutlet weak var cellImage: UIImageView!

    func transitionSourceRectView() -> UIImageView? {
        
        return cellImage
    }
    
    func displayImage( localURL: NSURL, image: UIImage ) -> Bool {
        
        assert( NSThread.isMainThread() )
        
        let newImageFile = localURL.lastPathComponent
        guard nil == currentImageFile || newImageFile == currentImageFile else { return true }

        cellImage.image = image
        currentImageFile = newImageFile

        return true
    }
    
    func clearCurrentImage() -> Void {
    
        currentImageFile = nil
        cellImage.image = UIImage( named: "961-book-32.png" )
    }
    
    func configure( tableView: UITableView, key: String, data: OLManagedObject? ) -> Void {
        
    }
}

protocol OLConfigureCell {
    
    associatedtype ObjectType
    
    func configureCell( object: ObjectType )
}



