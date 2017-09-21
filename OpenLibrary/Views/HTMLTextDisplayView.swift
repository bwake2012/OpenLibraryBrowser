//
//  HTMLTextDisplayView.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 6/10/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class HTMLFooterTextDisplayView: HTMLTextDisplayView {
    
    override init( frame: CGRect, textContainer: NSTextContainer? ) {
        
        super.init( frame: frame, textContainer: textContainer )
        
        displayHTML( self.text, textStyle: UIFontTextStyle.footnote.rawValue )
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init( coder: aDecoder )
        
        displayHTML( self.text, textStyle: UIFontTextStyle.footnote.rawValue )
    }
    
}

class HTMLTextDisplayView: UITextView {

    override init( frame: CGRect, textContainer: NSTextContainer? ) {
        
        super.init( frame: frame, textContainer: textContainer )
    
        displayHTML( self.text )
    }
    
    required init?(coder aDecoder: NSCoder) {
       
        super.init( coder: aDecoder )
        
        displayHTML( self.text )
    }
    
    func displayHTML( _ htmlText: String, textStyle: String = UIFontTextStyle.body.rawValue ) {
        
        assert( Thread.isMainThread )
        
        if let stringData = htmlText.data( using: String.Encoding.utf8, allowLossyConversion: false ) {
            
            do {
                let theAttributedString =
                    try NSMutableAttributedString(
                                data: stringData,
                                options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
                                documentAttributes: nil
                            )

                theAttributedString.enumerateAttribute(
                    NSAttributedStringKey.font,
                    in: NSRange( location: 0, length: theAttributedString.length ),
                    options: NSAttributedString.EnumerationOptions(rawValue: 0)
                ) {
                    (value, range, stop) -> Void in
                    
                    let newFont = UIFont.preferredFont( forTextStyle: UIFontTextStyle(rawValue: textStyle) )
                    
                    theAttributedString.removeAttribute( NSAttributedStringKey.font, range: range )
                    theAttributedString.addAttribute( NSAttributedStringKey.font, value: newFont, range: range )
                }
                self.attributedText = theAttributedString
            
                setNeedsLayout()
            }
            catch {
                
                print( "\(error)" )
            }
        }
    }
}
