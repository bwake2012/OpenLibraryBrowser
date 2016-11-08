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

    @IBAction func readOnline(_ sender: UIButton) {
        
        queryCoordinator?.readOnline()
        
//        performSegueWithIdentifier( "dismissDownload", sender: self )
        
    }

    @IBAction func downloadPDF(_ sender: UIButton) {
        
        queryCoordinator?.readTextPDF( sender )
    }

    @IBAction func downloadPlainText(_ sender: UIButton) {
        
        queryCoordinator?.readText( sender )
    }

    @IBAction func downloadZippedDaisy(_ sender: UIButton) {
    }

    @IBAction func downloadePub(_ sender: UIButton) {
        
        queryCoordinator?.readEPUB( sender )
    }

    @IBAction func downloadDjVu(_ sender: UIButton) {
        
        queryCoordinator?.readDjVu( sender )
    }

    @IBAction func downloadMOBI(_ sender: UIButton) {
        
        queryCoordinator?.readMOBI( sender )
    }

    @IBAction func sendToKindle(_ sender: UIButton) {
        
        queryCoordinator?.sendToKindle( sender )
    }

    @IBAction func closeView( _ sender: UIButton ) {
        
        performSegue( withIdentifier: "dismissDownload", sender: self )
    }
    
    // MARK: UIViewController
    override func viewDidLoad() {
        
        super.viewDidLoad()

        assert( nil != queryCoordinator )
        queryCoordinator?.updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear( animated )
        
        navigationController?.setNavigationBarHidden( false, animated: animated )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear( animated )
    }
    
    // MARK: Utility
    
    func updateHeading( _ heading: String ) {
        
        workTitleView.text = heading
    }
    
    func updateUI( _ eBookFile: OLEBookFile ) {
        
        assert( Thread.isMainThread )

        switch( eBookFile.format ) {
            
            case kFileTypeDjVu:
                downloadDjVuButton.isEnabled = true
                break
            case kFileTypeTextPDF:
                downloadPDFButton.isEnabled = true
                break
            case kFileTypeDjVuText:
                downloadPlainTextButton.isEnabled = true
            default:
                break
        }
    }
    
}
