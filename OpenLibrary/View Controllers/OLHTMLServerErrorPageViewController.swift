//
//  OLHTMLServerErrorPageViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 8/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class OLHTMLServerErrorPageViewController: UIViewController {

    @IBOutlet weak var errorPageText: UITextView!
    
    @IBAction func closeButtonTapped( sender: UIButton ) {
        
        self.dismissViewControllerAnimated( true, completion: nil )        
    }
}
