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
    @IBOutlet weak var editionName: UILabel!
    @IBOutlet weak var editionPublishDate: UILabel!

    override func configure( _ tableView: UITableView, indexPath: IndexPath, key: String, data: OLManagedObject? ) {
        
        assert( Thread.isMainThread )
        
        if let entry = data as? OLEditionDetail {
            
            let trimmedPrefix =
                entry.title_prefix.trimmingCharacters(
                        in: CharacterSet.whitespacesAndNewlines
                    )
            
            let trimmedTitle =
                entry.title.trimmingCharacters(
                        in: CharacterSet.whitespacesAndNewlines
                    )
            
            editionTitle.text =
                ( trimmedPrefix + " " + trimmedTitle ).trimmingCharacters(
                        in: CharacterSet.whitespacesAndNewlines
                    )

            editionSubTitle.text = entry.subtitle
//            editionSubTitle.text = entry.key + " " + entry.subtitle
            editionName.text = entry.edition_name
            editionPublishDate.text = entry.publish_date
            
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
            editionPublishDate.text = ""
            
            clearCurrentImage()
        }
        
    }
    
    override func prepareForReuse() {
        
        editionTitle.text = ""
        editionSubTitle.text = ""
        editionPublishDate.text = ""

        cellImage.image = nil
    }
}
