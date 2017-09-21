//
//  OLBookSearchViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 5/9/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit
    
typealias SaveSearchDictionary = ( _ searchDictionary: [String: String] ) -> Void

class OLBookSearchViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var generalSearch:   UITextField!
    @IBOutlet weak var titleSearch:     UITextField!
    @IBOutlet weak var authorSearch:    UITextField!
    @IBOutlet weak var isbnSearch:      UITextField!
    @IBOutlet weak var subjectSearch:   UITextField!
    @IBOutlet weak var placeSearch:     UITextField!
    @IBOutlet weak var personSearch:    UITextField!
    @IBOutlet weak var publisherSearch: UITextField!
    
    @IBOutlet weak var ebookOnlySwitch: UISwitch!
    
    @IBOutlet weak var aboutButton: UIButton!
    
    weak var activeField: UITextField?
    
    fileprivate var searchKeys = [String: String]()
    var saveSearchDictionary: SaveSearchDictionary?
    
    var fields = [(field: UITextField, key: String)]()
    
    @IBAction func ebookOnlySwitchChanged(_ sender: AnyObject) {
        
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        
        if let activeField = activeField {
            
            activeField.resignFirstResponder()
        }
    }
    
    @IBAction func searchButtonTapped(_ sender: UIButton) {
        
        if let activeField = activeField {
            
            activeField.resignFirstResponder()
        }
        
        assembleAndSaveSearchKeys()
    }
    
    // MARK: set initial search keys
    func initialSearchKeys( _ searchKeys: [String: String] ) {
        
        self.searchKeys = searchKeys
    }

    fileprivate func displaySearchKeys( _ searchKeys: [String: String] ) {
        
        for field in fields {
            
            if let text = searchKeys[field.key] {
                
                field.field.text = text
            } else {
                
                field.field.text = ""
            }
        }
        
        if let hasFullText = searchKeys["has_fulltext"] {
            
            ebookOnlySwitch.isOn = "true" == hasFullText
        }
        
    }
    
    // MARK: Swift classes
    deinit {
        NotificationCenter.default.removeObserver( self )
        fields = []
    }
    
    // MARK: UIViewController
    override func viewDidLoad() {

        super.viewDidLoad()
        
        fields =
            [( generalSearch, "q" ), (titleSearch, "title"), (authorSearch, "author"),
             (isbnSearch, "isbn"), (subjectSearch, "subject"), (placeSearch, "place"),
             (personSearch, "person"), (publisherSearch, "publisher")]
        
        displaySearchKeys( searchKeys )
        
        NotificationCenter.default.addObserver(self, selector: #selector(OLBookSearchViewController.keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(OLBookSearchViewController.keyboardWillBeHidden(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // what's our version?
        aboutButton.setTitle( Bundle.getAppVersionString() ?? "Version Not Found!", for: UIControlState() )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear( animated )
        
        navigationController?.setNavigationBarHidden( false, animated: animated )
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if "aboutOpenLibraryBrowser" == segue.identifier {
            
            if let vc = segue.destination as? OLLaunchViewController {
                
                vc.enableClose = true
            }
        }
    }
    
    
    // MARK: Notifications
    @objc func keyboardDidShow(_ notification: Notification) {

        if let activeField = self.activeField, let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height, right: 0.0)
            self.scrollView.contentInset = contentInsets
            self.scrollView.scrollIndicatorInsets = contentInsets
            var aRect = self.view.frame
            aRect.size.height -= keyboardSize.size.height
            if (!aRect.contains(activeField.frame.origin)) {
                
                self.scrollView.scrollRectToVisible(activeField.frame, animated: true)
            }
        }
    }
    
    @objc func keyboardWillBeHidden(_ notification: Notification) {
        let contentInsets = UIEdgeInsets.zero
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
    }
    
    // MARK: Search Keys
    
    fileprivate func assembleSearchKeys() -> [String: String] {
    
        var searchKeys = [String: String]()
        for field in fields {
            
            if let t = field.field.text , !t.isEmpty {
                
                searchKeys[field.key] = t
            }
        }
        
        // don't set the eBooksOnly parameter if no other fields have been set
        if !searchKeys.isEmpty && ebookOnlySwitch.isOn {
            searchKeys["has_fulltext"] = "true"
        }
    
        return searchKeys
    }

    fileprivate func assembleAndSaveSearchKeys() {

        searchKeys = assembleSearchKeys()
        if !searchKeys.isEmpty {
            
            if let saveSearchDictionary = saveSearchDictionary {
                
                saveSearchDictionary( searchKeys )
                
                performSegue( withIdentifier: "beginBookSearch", sender: self )
            }
        }
    }
}

extension OLBookSearchViewController: UITextFieldDelegate {
    
    // MARK: UITextFieldDelegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeField = nil
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeField = textField
    }
    
    func textFieldShouldReturn( _ textField: UITextField ) -> Bool {
        
        textField.resignFirstResponder()
        
        assembleAndSaveSearchKeys()
        
        return false
    }
    
}
