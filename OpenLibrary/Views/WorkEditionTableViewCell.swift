//
//  WorkEditionTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/14/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class WorkEditionTableViewCell: OLTableViewCell {

    @IBOutlet weak var editionTitle: UILabel!
    @IBOutlet weak var editionSubTitle: UILabel!

    func configure( entry: OLEditionDetail? ) {
        
        if let entry = entry   {
            
            let trimmedPrefix =
                entry.title_prefix.stringByTrimmingCharactersInSet(
                        NSCharacterSet.whitespaceAndNewlineCharacterSet()
                    )
            
            let trimmedTitle =
                entry.title.stringByTrimmingCharactersInSet(
                        NSCharacterSet.whitespaceAndNewlineCharacterSet()
                    )
            
            editionTitle.text =
                ( trimmedPrefix + " " + trimmedTitle ).stringByTrimmingCharactersInSet(
                        NSCharacterSet.whitespaceAndNewlineCharacterSet()
                    )

            editionSubTitle.text = entry.subtitle
//            editionSubTitle.text = entry.key + " " + entry.subtitle
            
            if entry.hasImage {
                
                clearCurrentImage()

            } else {
                
                if entry.physical_format == "Audio Cassette" {
                    
                    cellImage.image = UIImage( named: "565-cassette-tape.png" )
                    
                } else if entry.physical_format == "Audio CD" {
                    
                    cellImage.image = UIImage( named: "1043-album-disc.png" )
                    
                } else if entry.physical_format == "Microform" {
                    
                    cellImage.image = UIImage( named: "788-video-film-strip-toolbar.png" )
                    
                } else {
                    
                    clearCurrentImage()
                }
            }
        } else {
            editionTitle.text = ""
            editionSubTitle.text = ""
            
            clearCurrentImage()
        }
        
    }
    
}
