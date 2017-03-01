//
//  UIImageView+ImageAspectRatio.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/12/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

extension UIImage {
    
    func aspectFitSize( _ fitSize: CGSize ) -> CGSize {

        let resizeWidth  = ( self.size.width  * fitSize.height ) / self.size.height
        let resizeHeight = ( self.size.height * fitSize.width  ) / self.size.width
        
        let reSize =
            fitSize.width < resizeWidth ?
                CGSize( width: fitSize.width, height: resizeHeight ) :
                CGSize( width: resizeWidth, height: fitSize.height )
        
        return reSize
    }
    
    func aspectFitRect( _ fitRect: CGRect ) -> CGRect {
        
        let reSize = self.aspectFitSize( fitRect.size )
        
        let reRect =
            CGRect(
                    x: fitRect.origin.x + ( fitRect.size.width - reSize.width ) / 2,
                    y: fitRect.origin.y + ( fitRect.size.height - reSize.height ) / 2,
                    width: reSize.width, height: reSize.height
                )
        
        return reRect
    }
}

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
                    resize = testImage.aspectFitSize( originalSize )
                }

                for constraint in constraints {
                    if constraint.firstAttribute == .width && constraint.secondAttribute == .notAnAttribute {
                        constraint.constant = resize.width
                    }
                    if constraint.firstAttribute == .height && constraint.secondAttribute == .notAnAttribute {
                        constraint.constant = resize.height
                    }
                }
                
                setNeedsLayout()
            }
        }
    }
    
}
