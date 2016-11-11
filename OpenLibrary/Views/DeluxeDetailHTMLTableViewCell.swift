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
        
        var attributedText = NSMutableAttributedString( string: "" )
        if data.value.isEmpty {
            
            attributedText = NSMutableAttributedString( attributedString: data.attributedValue )

        } else {
            
            attributedText = convertHTMLText( htmlValue: data.value )
        }
        
        let newFont = UIFont.preferredFont( forTextStyle: UIFontTextStyle.body )
        
        attributedText.enumerateAttribute(
            NSFontAttributeName,
            in: NSRange( location: 0, length: attributedText.length ),
            options: NSAttributedString.EnumerationOptions(rawValue: 0)
        ) {
            (value, range, stop) -> Void in
            
            attributedText.removeAttribute( NSFontAttributeName, range: range )
            attributedText.addAttribute( NSFontAttributeName, value: newFont, range: range )
        }

        htmlView.attributedText = attributedText

        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func convertHTMLText( htmlValue: String ) -> NSMutableAttributedString {
        
        var valueText = htmlValue.replacingOccurrences( of: "\n", with: "<br>" )
        valueText = valueText.replacingOccurrences( of: "</p><br>", with: "</p>" )
        
        var theAttributedString = NSMutableAttributedString( string: "" )
        if let stringData = valueText.data( using: String.Encoding.utf8, allowLossyConversion: true ) {
            
            do {
                theAttributedString =
                    try NSMutableAttributedString(
                        data: stringData,
                        options: [
                            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType
                        ],
                        documentAttributes: nil
                )
                
                
            }
            catch {
                
                print( "\(error)" )
            }
            
        }

        return theAttributedString
    }
}

