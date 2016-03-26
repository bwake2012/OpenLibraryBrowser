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
        cellImage.image = nil
    }
}