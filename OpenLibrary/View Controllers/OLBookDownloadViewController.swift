//
//  OLBookDownloadViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 6/17/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class OLBookDownloadViewController: UIViewController, UIDocumentInteractionControllerDelegate {
    
    var queryCoordinator: BookDownloadCoordinator?
    
    @IBOutlet weak var workTitleView: UILabel!

    @IBOutlet weak var readOnlineButton: UIButton!

    @IBOutlet weak var downloadPDFButton: UIButton!
    @IBOutlet weak var downloadPlainTextButton: UIButton!
    @IBOutlet weak var downloadZippedDaisyButton: UIButton!
    @IBOutlet weak var downloadePubButton: UIButton!
    @IBOutlet weak var downloadDjVuButton: UIButton!
    @IBOutlet weak var downloadMOBIButton: UIButton!

    @IBOutlet weak var sendToKindleButton: UIButton!

    @IBAction func readOnline(sender: UIButton) {
        
        performSegueWithIdentifier( "dismissDownload", sender: self )
        
    }

    @IBAction func downloadPDF(sender: UIButton) {
    }

    @IBAction func downloadPlainText(sender: UIButton) {
    }

    @IBAction func downloadZippedDaisy(sender: UIButton) {
    }

    @IBAction func downloadePub(sender: UIButton) {
    }

    @IBAction func downloadDjVu(sender: UIButton) {
    }

    @IBAction func downloadMOBI(sender: UIButton) {
    }

    @IBAction func sendToKindle(sender: UIButton) {
    }

    // MARK: UIViewController
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        assert( nil != queryCoordinator )
        
        queryCoordinator!.updateUI()
    }
}
