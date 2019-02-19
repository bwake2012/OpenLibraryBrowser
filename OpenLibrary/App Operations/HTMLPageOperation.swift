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


class HTMLPageOperation: PSOperation {
    // MARK: Properties

    fileprivate let presentationContext: UIViewController?
    
    var operationName = "HTML page presentation"
    var response:HTTPURLResponse?
    var operationError: NSError?
    var data: Data?
    var url: URL?

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
        
        if let htmlPageController = storyboard.instantiateViewController( withIdentifier: sceneID ) as? OLHTMLErrorViewController {
        
            var theAttributedString = NSMutableAttributedString()
            do {
                
                let htmlOptions = [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html]
                if let data = data {
                
                    try theAttributedString.read( from: data, options: htmlOptions, documentAttributes: nil )

                } else if let url = url {
                
                    try theAttributedString.read( from: url, options: htmlOptions, documentAttributes: nil )
                
                }
            }
                
            catch {
                
                theAttributedString.replaceCharacters(
                        in: NSRange( location: 0, length: 0),
                        with: "Unable to display openlibrary.org server error page."
                    )
            }
            
            let string: String = theAttributedString.string
            theAttributedString = NSMutableAttributedString( string: string )
            
            let newFont = UIFont.preferredFont( forTextStyle: UIFont.TextStyle.body )
            let range = NSRange( location: 0, length: theAttributedString.length )
            theAttributedString.addAttribute( NSAttributedString.Key.font, value: newFont, range: range )
            
            htmlPageController.htmlString = theAttributedString
            
            htmlPageController.nameString = operationName
            
            htmlPageController.urlString = operationError?.userInfo[hostURLKey] as? String ?? ""

            DispatchQueue.main.async {
                
                presentationContext.present(
                        htmlPageController, animated: true, completion: self.presentationComplete
                    )
            }
            
            if let url = url {
                
                do {
                    /*
                     Delete the file at this URL. It's not the file we were looking for.
                     Also, swallow any error, because we don't really care about it.
                     */
                    try FileManager.default.removeItem( at: url )
                }
                catch {}
            }
        }
    }

    func presentationComplete() -> Void {
        
        finish()
    }
}
