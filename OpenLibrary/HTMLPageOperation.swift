/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows how to present an alert as part of an operation.
*/

import UIKit

import PSOperations

class HTMLPageOperation: Operation {
    // MARK: Properties

    private lazy var htmlPageController = UIViewController()
    private let presentationContext: UIViewController?
    
    var title: String? {
        get {
            return htmlPageController.title
        }

        set {
            htmlPageController.title = newValue
            name = newValue
        }
    }
    
    var data: NSData?
    var url: NSURL?

    // MARK: Initialization
    
    init(presentationContext: UIViewController? = nil) {
        self.presentationContext = presentationContext ?? UIApplication.sharedApplication().keyWindow?.rootViewController

        super.init()
        
        addCondition(AlertPresentation())
        
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

        dispatch_async(dispatch_get_main_queue()) {
            
            let sceneID = "htmlServerErrorPage"
            
            let storyboard = UIStoryboard( name: "main", bundle:nil )
            
            self.htmlPageController = storyboard.instantiateViewControllerWithIdentifier( sceneID )
            
            presentationContext.presentViewController( self.htmlPageController, animated: true, completion: nil )
        }
    }
}
