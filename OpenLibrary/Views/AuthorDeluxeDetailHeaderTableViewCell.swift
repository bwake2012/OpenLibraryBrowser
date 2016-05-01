//
//  AuthorDeluxeDetailHeaderTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/28/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class AuthorDeluxeDetailHeaderTableViewCell: UITableViewCell {

    @IBOutlet var displayLargePhoto: UIButton!
    @IBOutlet var authorName: UILabel!
    @IBOutlet var authorPhoto: UIImageView!
    
    func configure( authorDetail: OLAuthorDetail ) {
        
        self.displayLargePhoto.enabled = authorDetail.hasImage
        
        self.authorName.text = authorDetail.name
        
        if !authorDetail.hasImage {
            self.authorPhoto.image = UIImage( named: "253-person.png" )
        } else {
            
            self.authorPhoto.displayFromURL( authorDetail.localURL( "M" ) )
        }
    }
    
}
