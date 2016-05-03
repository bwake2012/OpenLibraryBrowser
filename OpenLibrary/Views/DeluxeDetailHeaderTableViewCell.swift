//
//  DeluxeDetailHeaderTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/28/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class DeluxeDetailHeaderTableViewCell: UITableViewCell {

    @IBOutlet weak var deluxeHeading: UILabel!
    @IBOutlet weak var deluxeImage: UIImageView!
    
    func configure( detail: OLManagedObject ) {

        self.deluxeHeading.text = detail.heading
        
        if !detail.hasImage {
            self.deluxeImage.image = UIImage( named: detail.defaultImageName )
        } else {
            
            self.deluxeImage.displayFromURL( detail.localURL( "M" ) )
        }
    }
    
}
