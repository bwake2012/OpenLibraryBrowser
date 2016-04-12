//
//  UIImageView+ImageAspectRatio.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/12/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class AspectRatioImageView: UIImageView {
    
    var originalSize: CGSize?
    
    override var image: UIImage? {

        willSet( newImage ) {
            if nil == originalSize {
                originalSize = bounds.size
            }
    
            if let originalSize = originalSize {
                
                var resize = CGSize( width: 0, height: 0 )
                if let testImage = newImage {
                    let resizeWidth  = ( testImage.size.width  * originalSize.height ) / testImage.size.height
                    let resizeHeight = ( testImage.size.height * originalSize.width  ) / testImage.size.width
                    
                    resize =
                        originalSize.width < resizeWidth ?
                            CGSize( width: originalSize.width, height: resizeHeight ) :
                            CGSize( width: resizeWidth, height: originalSize.height )
                }
                for constraint in constraints {
                    if constraint.firstAttribute == .Width && constraint.secondAttribute == .NotAnAttribute {
                        constraint.constant = resize.width
                    } else if constraint.firstAttribute == .Height && constraint.secondAttribute == .NotAnAttribute {
                        constraint.constant = resize.height
                    }
                }
                
                self.superview?.layoutIfNeeded()
            }
        }
    }
}
