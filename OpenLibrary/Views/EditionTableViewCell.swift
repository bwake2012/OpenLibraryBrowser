//
//  AuthorEditionsTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/14/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class EditionTableViewCell: OLTableViewCell {

    @IBOutlet weak var workTitle: UILabel!
    @IBOutlet weak var workSubTitle: UILabel!

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
            
            workTitle.text =
                ( trimmedPrefix + " " + trimmedTitle ).stringByTrimmingCharactersInSet(
                        NSCharacterSet.whitespaceAndNewlineCharacterSet()
                    )

            workSubTitle.text = entry.subtitle
            
        } else {
            workTitle.text = ""
            workSubTitle.text = ""
        }
    }
}
