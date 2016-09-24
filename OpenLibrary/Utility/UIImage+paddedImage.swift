//
//  UIImage+paddedImage.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 9/23/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

extension UIImage {
    
    func paddedImage( left: CGFloat = 0.0, top: CGFloat = 0.0, right: CGFloat, bottom: CGFloat, backgroundColor: UIColor = UIColor.whiteColor() ) -> UIImage? {
        
        let width: CGFloat = self.size.width + left + right
        let height: CGFloat = self.size.height + top + bottom
        
        UIGraphicsBeginImageContextWithOptions( CGSize( width: width, height: height ), false, 0 )
        
        guard let context: CGContext = UIGraphicsGetCurrentContext() else { return nil }

        UIGraphicsPushContext( context )
        
        CGContextSetFillColorWithColor( context, backgroundColor.CGColor )
        CGContextFillRect( context, CGRect( x: 0, y: 0, width: width, height: height ) )
        
        self.drawAtPoint( CGPoint(x: left, y: top ) )
        
        UIGraphicsPopContext()
        
        let imageWithPadding = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()
        
        return imageWithPadding
    }
}
