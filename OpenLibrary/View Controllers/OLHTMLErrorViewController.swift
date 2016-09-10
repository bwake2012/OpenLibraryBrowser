//
//  OLHTMLErrorViewController.swift
//  Test Reachability
//
//  Created by Bob Wakefield on 9/4/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class OLHTMLErrorViewController: UIViewController {

    @IBOutlet private weak var operationName: UILabel!
    @IBOutlet private weak var url: UILabel!
    @IBOutlet private weak var htmlView: UITextView!
    
    var nameString = ""
    var urlString = ""
    var htmlString = NSAttributedString()
    
    @IBAction func tappedOK(sender: UIButton) {
        
        dismissViewControllerAnimated( true, completion: nil )
    }
    
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
    }
    
    override func viewDidLoad() {
        
        operationName.text = nameString
        url.text = urlString
        htmlView.attributedText = htmlString
    }
}
