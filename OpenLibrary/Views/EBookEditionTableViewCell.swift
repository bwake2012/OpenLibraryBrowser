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
    @IBOutlet weak var eBookStatus: UILabel!

    func configure( _ tableView: UITableView, key: String, eBookStatusText: String, data: OLManagedObject? ) {
        
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
            
            if !entry.by_statement.isEmpty {
                
                authorName.text = entry.by_statement
                
            } else {
                
                authorName.text = entry.author_names.joined( separator: ", " )
            }
            
            eBookStatus.text = eBookStatusText
            
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
    
    override func prepareForReuse() {
        
        editionTitle.text = ""
        editionSubTitle.text = ""
        authorName.text = ""
        
        cellImage.image = nil
    }
}
