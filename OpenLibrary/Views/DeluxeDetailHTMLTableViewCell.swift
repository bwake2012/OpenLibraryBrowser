//
//  DeluxeDetailHTMLTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 6/9/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class DeluxeDetailHTMLTableViewCell: DeluxeDetailTableViewCell {
    
    @IBOutlet weak var htmlView: UITextView!
    @IBOutlet weak var captionView: UILabel!

    override func configure( data: DeluxeData ) {
        
        captionView.text = data.caption
        
        if let stringData = data.value.dataUsingEncoding( NSUTF8StringEncoding, allowLossyConversion: false ) {
        
            let theAttributedString =
                try! NSMutableAttributedString(
                            data: stringData,
                            options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType],
                            documentAttributes: nil
                        )

            theAttributedString.enumerateAttribute(
                    NSFontAttributeName,
                    inRange: NSRange( location: 0, length: theAttributedString.length ),
                    options: NSAttributedStringEnumerationOptions(rawValue: 0)
                ) {
                    (value, range, stop) -> Void in
                    
                    let newFont = UIFont.preferredFontForTextStyle( UIFontTextStyleBody )
                    
                    theAttributedString.removeAttribute( NSFontAttributeName, range: range )
                    theAttributedString.addAttribute( NSFontAttributeName, value: newFont, range: range )
                }
            
            htmlView.attributedText = theAttributedString
            
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
}

