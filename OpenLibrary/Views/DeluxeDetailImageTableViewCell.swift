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
        
        assert( NSThread.isMainThread() )
        
        let success = deluxeImage.displayFromURL( url )
        if success {
            activityIndicator.stopAnimating()
        }
        return success
    }
}

