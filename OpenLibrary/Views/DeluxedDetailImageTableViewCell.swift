//
//  DeluxedDetailImageTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 5/2/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class DeluxedDetailImageTableViewCell: UITableViewCell {

    @IBOutlet weak var deluxeImage: AspectRatioImageView!
    
    func displayFromURL( url: NSURL ) -> Bool {
        
        return deluxeImage.displayFromURL( url )
    }
}
