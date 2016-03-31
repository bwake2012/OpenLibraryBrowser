//
//  UIImage+DisplayFromURLswift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/18/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

extension UIImageView {
    
    func displayFromURL( localURL: NSURL ) -> Bool {
        
        if let data = NSData( contentsOfURL: localURL ) {

            if let image = UIImage( data: data ) {
                
                self.image = image
                return true
            }
        }

        self.image = nil
        return false
    }
}
