//
//  UIImageView+DisplayFromURLswift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/18/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

extension UIImageView {
    
    @discardableResult func displayFromURL( _ localURL: URL ) -> Bool {
        
        if localURL.isFileURL {

            if let data = try? Data( contentsOf: localURL ) {

                if let image = UIImage( data: data ) {
                    
                    self.image = image
                    return true
                }
            }
        }
        
        return false
    }
}
