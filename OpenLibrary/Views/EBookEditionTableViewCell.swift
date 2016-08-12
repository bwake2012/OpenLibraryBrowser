//
//  EBookEditionTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/14/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class EbookEditionTableViewCell: OLTableViewCell {

    @IBOutlet weak var editionTitle: UILabel!
    @IBOutlet weak var editionSubTitle: UILabel!
    @IBOutlet weak var authorName: UILabel!

    override func configure( tableView: UITableView, indexPath: NSIndexPath, data: OLManagedObject? ) {
        
        if let entry = data as? OLEditionDetail {
            
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
            
            if !entry.by_statement.isEmpty {
                
                authorName.text = entry.by_statement
                
            } else {
                
                authorName.text = entry.author_names.joinWithSeparator( ", " )
            }
            
            if entry.hasImage {
                
                clearCurrentImage()

            } else {
                
                if entry.physical_format == "Audio Cassette" {
                    
                    cellImage.image = UIImage( named: "565-cassette-tape.png" )
                    
                } else if entry.physical_format == "Audio CD" {
                    
                    cellImage.image = UIImage( named: "1043-album-disc.png" )
                    
                } else if entry.physical_format == "Microform" {
                    
                    cellImage.image = UIImage( named: "788-video-film-strip.png" )
                    
                } else {
                    
                    clearCurrentImage()
                }
            }
        } else {
            editionTitle.text = ""
            editionSubTitle.text = ""
            authorName.text = ""
            
            clearCurrentImage()
        }
        
    }
    
}
