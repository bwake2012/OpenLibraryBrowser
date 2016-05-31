//
//  AuthorWorksTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/14/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class AuthorWorksTableViewCell: OLTableViewCell {

    @IBOutlet weak var workTitle: UILabel!
    @IBOutlet weak var workSubTitle: UILabel!

    func configure( entry: OLWorkDetail? ) {
        
        if let entry = entry   {
            
            workTitle.text = entry.title
            workSubTitle.text = "\(entry.subtitle)"
//            workSubTitle.text = "\(entry.index) \(entry.key) \(entry.subtitle)"
            
            
        } else {

            workTitle.text = ""
            workSubTitle.text = ""

        }

        clearCurrentImage()
    }
}
