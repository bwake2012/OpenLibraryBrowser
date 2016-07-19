//
//  HTMLTextDisplayView.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 6/10/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class HTMLTextDisplayView: UITextView {

    override init( frame: CGRect, textContainer: NSTextContainer? ) {
        
        super.init( frame: frame, textContainer: textContainer )
    
        displayHTML( self.text )
    }
    
    required init?(coder aDecoder: NSCoder) {
       
        super.init( coder: aDecoder )
        
        displayHTML( self.text )
    }
    
    func displayHTML( htmlText: String ) {
        
        if let stringData = htmlText.dataUsingEncoding( NSUTF8StringEncoding, allowLossyConversion: false ) {
            
            do {
                let theAttributedString =
                    try NSMutableAttributedString(
                        data: stringData,
                        options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType],
                        documentAttributes: nil
                )
            
                self.attributedText = theAttributedString
            
                setNeedsLayout()
            }
            catch {
                
                print( "\(error)" )
            }
        }
    }
}
