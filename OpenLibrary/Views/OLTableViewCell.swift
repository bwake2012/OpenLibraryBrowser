//
//  OLTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/19/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

protocol OLCell: class {
    
    func displayImage( _ localURL: URL, image: UIImage ) -> Bool
    func clearCurrentImage() -> Void
    func configure( _ tableView: UITableView, indexPath: IndexPath, key: String, data: OLManagedObject? ) -> Void
    func imageSize() -> CGSize?
}

class OLTableViewCell: UITableViewCell, OLCell {

    var currentImageFile: String?
    
    @IBOutlet weak var cellImage: UIImageView!

    func transitionSourceRectView() -> UIImageView? {
        
        return cellImage
    }
    
    func imageSize() -> CGSize? {
        
        return cellImage.bounds.size
    }
    
    func displayImage( _ localURL: URL, image: UIImage ) -> Bool {
        
        assert( Thread.isMainThread )
        
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
    
    func configure( _ tableView: UITableView, indexPath: IndexPath, key: String, data: OLManagedObject? ) -> Void {
        
    }
}

protocol OLConfigureCell {
    
    associatedtype ObjectType
    
    func configureCell( _ object: ObjectType )
}



