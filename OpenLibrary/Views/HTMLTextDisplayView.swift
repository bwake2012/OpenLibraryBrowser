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
        
        displayHTML( self.text, textStyle: UIFontTextStyleFootnote )
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init( coder: aDecoder )
        
        displayHTML( self.text, textStyle: UIFontTextStyleFootnote )
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
    
    func displayHTML( htmlText: String, textStyle: String = UIFontTextStyleBody ) {
        
        assert( NSThread.isMainThread() )
        
        if let stringData = htmlText.dataUsingEncoding( NSUTF8StringEncoding, allowLossyConversion: false ) {
            
            do {
                let theAttributedString =
                    try NSMutableAttributedString(
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
                    
                    let newFont = UIFont.preferredFontForTextStyle( textStyle )
                    
                    theAttributedString.removeAttribute( NSFontAttributeName, range: range )
                    theAttributedString.addAttribute( NSFontAttributeName, value: newFont, range: range )
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
