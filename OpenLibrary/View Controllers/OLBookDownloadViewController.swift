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
        
        queryCoordinator?.readOnline()
        
//        performSegueWithIdentifier( "dismissDownload", sender: self )
        
    }

    @IBAction func downloadPDF(sender: UIButton) {
        
        queryCoordinator?.readTextPDF( sender )
    }

    @IBAction func downloadPlainText(sender: UIButton) {
        
        queryCoordinator?.readText( sender )
    }

    @IBAction func downloadZippedDaisy(sender: UIButton) {
    }

    @IBAction func downloadePub(sender: UIButton) {
        
        queryCoordinator?.readEPUB( sender )
    }

    @IBAction func downloadDjVu(sender: UIButton) {
        
        queryCoordinator?.readDjVu( sender )
    }

    @IBAction func downloadMOBI(sender: UIButton) {
        
        queryCoordinator?.readMOBI( sender )
    }

    @IBAction func sendToKindle(sender: UIButton) {
        
        queryCoordinator?.sendToKindle( sender )
    }

    @IBAction func closeView( sender: UIButton ) {
        
        performSegueWithIdentifier( "dismissDownload", sender: self )
    }
    
    // MARK: UIViewController
    override func viewDidLoad() {
        
        super.viewDidLoad()

        assert( nil != queryCoordinator )
        queryCoordinator?.updateUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear( animated )
        
        navigationController?.setNavigationBarHidden( false, animated: animated )
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear( animated )
    }
    
    // MARK: Utility
    
    func updateHeading( heading: String ) {
        
        workTitleView.text = heading
    }
    
    func updateUI( eBookFile: OLEBookFile ) {
        
        assert( NSThread.isMainThread() )

        switch( eBookFile.format ) {
            
            case kFileTypeDjVu:
                downloadDjVuButton.enabled = true
                break
            case kFileTypeTextPDF:
                downloadPDFButton.enabled = true
                break
            case kFileTypeDjVuText:
                downloadPlainTextButton.enabled = true
            default:
                break
        }
    }
    
}
