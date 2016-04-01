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
    
    @NSManaged var sequence: Int64
    @NSManaged var index: Int64
    @NSManaged var key: String
    @NSManaged var name: String
    @NSManaged var birth_date: NSDate?
    @NSManaged var death_date: NSDate?
    @NSManaged var type: String
    @NSManaged var top_work: String?
    @NSManaged var work_count: Int64
    @NSManaged var has_photos: Bool

    @NSManaged var toDetail: OLAuthorDetail?

    var havePhoto = HasPhoto.unknown
    
    var searchInfo: SearchInfo {
        
        return SearchInfo( objectID: self.objectID, key: self.key, work_count: Int( self.work_count ) )
    }
    
    override func awakeFromFetch() {
        
        super.awakeFromFetch()
        
        havePhoto = has_photos ? HasPhoto.unknown : HasPhoto.none
    }
    
    func localURL( size: String ) -> NSURL {
        
        let key = self.key
        return super.localURL( key, size: size )
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
                            
                            havePhoto = detail.hasPhotos ? .id : .none
                            
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
                    setValue( havePhoto.rawValue, forKey: kHasPhoto )
                    didChangeValueForKey( kHasPhoto )
                }
            }
        }
            
        return bDisplayed ? .local : havePhoto
    }

}
