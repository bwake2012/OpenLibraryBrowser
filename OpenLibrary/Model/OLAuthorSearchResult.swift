//
//  OLAuthorSearchResult.swift
//  OpenLibraryBrowser
//
//  Created by Bob Wakefield on 2/22/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData
import UIKit

//import BNRCoreDataStack

class OLAuthorSearchResult: OLManagedObject {
    
    fileprivate let kHasPhoto = "has_photos"

    // MARK: Search Info
    struct SearchInfo {
        let objectID: NSManagedObjectID
        let key: String
        let work_count: Int
    }
    
    // MARK: Static Properties
    
    static let entityName = "AuthorSearchResult"
    
    var havePhoto = HasPhoto.unknown
    
    var searchInfo: SearchInfo {
        
        return SearchInfo( objectID: self.objectID, key: self.key, work_count: Int( self.work_count ) )
    }
    
    override func awakeFromFetch() {
        
        super.awakeFromFetch()
        
        if let detail = toDetail {
            havePhoto = detail.hasImage ? .id : .none
        } else {
            havePhoto = has_photos ? HasPhoto.unknown : HasPhoto.none
        }
    }
    
    override func localURL( _ size: String, index: Int = 0 ) -> URL {
        
        let docFolder = try! FileManager.default.url( for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false )
        
        let imagesFolder = docFolder.appendingPathComponent( "images" )
        
        let parts = self.key.components( separatedBy: "/" )
        let goodParts = parts.filter { (x) -> Bool in !x.isEmpty }
        
        let imagesSubFolder = imagesFolder.appendingPathComponent( goodParts[0] )
        
        var fileName = "\(goodParts[1])-\(size)"
        if 0 < index {
            fileName += "\(index)"
        }
        fileName += ".jpg"
        let url = imagesSubFolder.appendingPathComponent( fileName )
        
        return url
    }

    func displayThumbnail( _ imageView: UIImageView ) -> HasPhoto {
        
        var bDisplayed = false
        if .none != havePhoto {
            
            let localURL = self.localURL( "S" )
            bDisplayed = imageView.displayFromURL( localURL )
            
            if .local != havePhoto {

                switch havePhoto {
                    
                case .unknown:
                    if bDisplayed {
                        
                        havePhoto = .local
                        
                    } else {

                        if let detail = self.toDetail {
                            
                            havePhoto = detail.hasImage ? .id : .none
                            
                        } else {
                            
                            havePhoto = .olid

                        }
                    }
                    
                case .olid:
                    havePhoto = bDisplayed ? .local : .authorDetail
                    
                case .id, .authorDetail:
                    havePhoto = bDisplayed ? .local : .none
                    
                case .local:
                    break
                    
                case .none:
                    assert( .none != havePhoto )
                }

                if bDisplayed || .none == havePhoto {
                    
                    willChangeValue( forKey: kHasPhoto )
                    setValue( bDisplayed, forKey: kHasPhoto )
                    didChangeValue( forKey: kHasPhoto )
                }
            }
        }
            
        return bDisplayed ? .local : havePhoto
    }
}

extension OLAuthorSearchResult {
    
    class func buildFetchRequest() -> NSFetchRequest< OLAuthorSearchResult > {
        
        return NSFetchRequest( entityName: OLAuthorSearchResult.entityName )
    }
}

