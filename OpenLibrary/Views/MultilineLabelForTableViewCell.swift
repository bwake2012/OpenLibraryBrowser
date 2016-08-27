//
//  MultilineLabelForTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 8/27/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class MultilineLabelForTableViewCell: UILabel {

    override internal func layoutSubviews() {
        
        super.layoutSubviews()
        
        self.preferredMaxLayoutWidth = self.bounds.width
        
        super.layoutSubviews()
    }
    
    override internal var bounds: CGRect {
        
        didSet {
            
            self.preferredMaxLayoutWidth = self.bounds.width
        }
    }

    override internal var frame: CGRect {
        
        didSet {
            
            self.preferredMaxLayoutWidth = self.frame.width
        }
    }
}
