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

        attributedText = adjustFont(text: attributedText, to: .body)

        if let textColor = UIColor(named: "defaultText") {
            attributedText = adjustColor(text: attributedText, to: textColor)
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
                            NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html
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

    func adjustFont(text: NSAttributedString, to style: UIFont.TextStyle) -> NSMutableAttributedString {

        let newFont = UIFont.preferredFont( forTextStyle: style )

        let attributedText = NSMutableAttributedString( attributedString: text )

        attributedText.enumerateAttribute(
            NSAttributedString.Key.font,
            in: NSRange( location: 0, length: attributedText.length ),
            options: NSAttributedString.EnumerationOptions(rawValue: 0)
        ) {
            (value, range, stop) -> Void in

            attributedText.removeAttribute( NSAttributedString.Key.font, range: range )
            attributedText.addAttribute( NSAttributedString.Key.font, value: newFont, range: range )
        }

        return attributedText
    }

    func adjustColor(text: NSAttributedString, to newColor: UIColor) -> NSMutableAttributedString {

        let attributedText = NSMutableAttributedString( attributedString: text )

        attributedText.enumerateAttribute(
            NSAttributedString.Key.foregroundColor,
            in: NSRange( location: 0, length: attributedText.length ),
            options: NSAttributedString.EnumerationOptions(rawValue: 0)
        ) {
            (value, range, stop) -> Void in

            attributedText.removeAttribute( NSAttributedString.Key.foregroundColor, range: range )
            attributedText.addAttribute( NSAttributedString.Key.foregroundColor, value: newColor, range: range )
        }

        return attributedText
    }

}

