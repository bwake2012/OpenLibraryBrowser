//
//  OLHTMLErrorViewController.swift
//  Test Reachability
//
//  Created by Bob Wakefield on 9/4/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class OLHTMLErrorViewController: UIViewController {

    @IBOutlet fileprivate weak var operationName: UILabel!
    @IBOutlet fileprivate weak var url: UILabel!
    @IBOutlet fileprivate weak var htmlView: UITextView!
    
    var nameString = ""
    var urlString = ""
    var htmlString = NSAttributedString()
    
    @IBAction func tappedOK(_ sender: UIButton) {
        
        dismiss( animated: true, completion: nil )
    }
    
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        operationName.text = nameString
        url.text = urlString
        htmlView.attributedText = htmlString
    }
}
