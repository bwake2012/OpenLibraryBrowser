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
    
    func displayFromURL( _ url: URL ) -> Bool {
        
        assert( Thread.isMainThread )
        
        let success = deluxeImage.displayFromURL( url )
        if success {
            activityIndicator.stopAnimating()
        }
        return success
    }
}

