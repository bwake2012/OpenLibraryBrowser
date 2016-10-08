//
//  OLAuthorSearchResult.swift
//  OpenLibraryBrowser
//
//  Created by Bob Wakefield on 2/22/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

import BNRCoreDataStack

class OLAuthorSearchResult: OLManagedObject, CoreDataModelable {
    
    private let kHasPhoto = "has_photos"

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
    
    override func localURL( size: String, index: Int = 0 ) -> NSURL {
        
        let docFolder = try! NSFileManager.defaultManager().URLForDirectory( .CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false )
        
        let imagesFolder = docFolder.URLByAppendingPathComponent( "images" )
        
        let parts = self.key.componentsSeparatedByString( "/" )
        let goodParts = parts.filter { (x) -> Bool in !x.isEmpty }
        
        let imagesSubFolder = imagesFolder.URLByAppendingPathComponent( goodParts[0] )
        
        var fileName = "\(goodParts[1])-\(size)"
        if 0 < index {
            fileName += "\(index)"
        }
        fileName += ".jpg"
        let url = imagesSubFolder.URLByAppendingPathComponent( fileName )
        
        return url
    }

    func displayThumbnail( imageView: UIImageView ) -> HasPhoto {
        
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
                    
                    willChangeValueForKey( kHasPhoto )
                    setValue( bDisplayed, forKey: kHasPhoto )
                    didChangeValueForKey( kHasPhoto )
                }
            }
        }
            
        return bDisplayed ? .local : havePhoto
    }

}
