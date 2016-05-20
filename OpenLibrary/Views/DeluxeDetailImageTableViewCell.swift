//
//  DeluxedDetailImageTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 5/2/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class DeluxeDetailImageTableViewCell: DeluxeDetailTableViewCell {

    @IBOutlet weak var deluxeImage: AspectRatioImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    func displayFromURL( url: NSURL ) -> Bool {
        
        let success = deluxeImage.displayFromURL( url )
        if success {
            activityIndicator.stopAnimating()
        }
        return success
    }
}

extension DeluxeDetailImageTableViewCell {
    
    override class func registerCell( tableView: UITableView ) {
        
        registerCell( tableView, className: DeluxeDetail.imageAuthor.rawValue )
        registerCell( tableView, className: DeluxeDetail.imageBook.rawValue )
    }
    
}