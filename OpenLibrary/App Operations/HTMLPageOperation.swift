/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows how to present an alert as part of an operation.
*/

import UIKit

import PSOperations

/**
 The purpose of this enum is to simply provide a non-constructible
 type to be used with `MutuallyExclusive<T>`.
 */
public enum HTMLPage { }

/// A condition describing that the targeted operation may present an alert.
public typealias HTMLPresentation = MutuallyExclusive<HTMLPage>


class HTMLPageOperation: Operation {
    // MARK: Properties

    private let presentationContext: UIViewController?
    
    var operationName = ""
    
    var operationError: NSError?
    var data: NSData?
    var url: NSURL?

    // MARK: Initialization
    
    init(presentationContext: UIViewController? = nil) {

        self.presentationContext = presentationContext ?? UIApplication.topViewController()

        super.init()
        
        addCondition(HTMLPresentation())
        
        /*
            This operation modifies the view controller hierarchy.
            Doing this while other such operations are executing can lead to
            inconsistencies in UIKit. So, let's make them mutally exclusive.
        */
        addCondition(MutuallyExclusive<UIViewController>())
    }
    
    
    override func execute() {

        guard let presentationContext = presentationContext else {

            finish()
            return
        }

        let sceneID = "htmlServerErrorPage"
        
        let storyboard = UIStoryboard( name: "Main", bundle:nil )
        
        if let htmlPageController = storyboard.instantiateViewControllerWithIdentifier( sceneID ) as? OLHTMLErrorViewController {
        
            let theAttributedString = NSMutableAttributedString()
            do {
                
                let htmlOptions = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType]
                if let data = data {
                
                    try theAttributedString.readFromData( data, options: htmlOptions, documentAttributes: nil )

                } else if let url = url {
                
                    try theAttributedString.readFromURL( url, options: htmlOptions, documentAttributes: nil )
                
                }
            }
                
            catch {
                
                theAttributedString.replaceCharactersInRange(
                        NSRange( location: 0, length: 0),
                        withString: "Unable to display openlibrary.org server error page."
                    )
            }
            
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
            
            htmlPageController.htmlString = theAttributedString
            htmlPageController.nameString = operationName

            dispatch_async(dispatch_get_main_queue()) {
                
                presentationContext.presentViewController( htmlPageController, animated: true, completion: nil )
                self.finish()
            }
        }
    }
}
