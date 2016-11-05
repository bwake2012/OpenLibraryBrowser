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

    override func configure( _ data: DeluxeData ) {
        
        assert( Thread.isMainThread )
        
        captionView.text = data.caption
        
        if let stringData = data.value.data( using: String.Encoding.utf8, allowLossyConversion: false ) {
        
            do {
                let theAttributedString =
                    try NSMutableAttributedString(
                                data: stringData,
                                options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType],
                                documentAttributes: nil
                            )

                theAttributedString.enumerateAttribute(
                        NSFontAttributeName,
                        in: NSRange( location: 0, length: theAttributedString.length ),
                        options: NSAttributedString.EnumerationOptions(rawValue: 0)
                    ) {
                        (value, range, stop) -> Void in
                        
                        let newFont = UIFont.preferredFont( forTextStyle: UIFontTextStyle.body )
                        
                        theAttributedString.removeAttribute( NSFontAttributeName, range: range )
                        theAttributedString.addAttribute( NSFontAttributeName, value: newFont, range: range )
                    }
                
                htmlView.attributedText = theAttributedString
            }
            catch {
                
                print( "\(error)" )
            }
            
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
}

