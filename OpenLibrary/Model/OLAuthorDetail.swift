//
//  OLAuthorDetail.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/1/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

import BNRCoreDataStack


/// An object to represent a parsed author search result.
private class ParsedSearchResult: OpenLibraryObject {
    
    // MARK: Properties.
    
    let key: String
    let name: String
    let personal_name: String
    let birth_date: String
    let death_date: String
    
    let photos: [Int]                // transformable
    let links: [[String: String]]    // transformable
    let bio: String
    let alternate_names: [String]    // transformable
    
    let wikipedia: String
    
    let revision: Int64
    let latest_revision: Int64
    
    let created: NSDate?
    let last_modified: NSDate?
    
    let type: String
    
    // MARK: Class Factory
    
    class func fromJSON ( match: [String: AnyObject] ) -> ParsedSearchResult? {
        
        guard let key = match["key"] as? String else { return nil }
        
        guard let name = match["name"] as? String else { return nil }
        
        let personal_name = match["personal_name"] as? String ?? ""
        
        let birth_date = OpenLibraryObject.OLDateStamp( match["birth_date"] )
        let death_date = OpenLibraryObject.OLDateStamp( match["death_date"] )
        
        let photos = OpenLibraryObject.OLIntArray( match["photos"] )
        
        let links = OpenLibraryObject.OLLinks( match )
        
        let bioText = OpenLibraryObject.OLText( match["bio"] )
        
        let alternate_names = OpenLibraryObject.OLStringArray( match["alternate_names"] )
        
        let wikipedia = OpenLibraryObject.OLString( match["wikipedia"] )
        
        var revision = match["revision"] as? Int64
        var latest_revision = match["latest_revision"] as? Int64
        if nil == revision && nil != latest_revision {
            
            revision = latest_revision
            
        } else if nil == latest_revision && nil != revision {
            
            latest_revision = revision
            
        } else if nil == revision && nil == latest_revision {
            
            revision = Int64( 0 )
            latest_revision = Int64( 0 )
            
        }
        
        var created = OpenLibraryObject.OLTimeStamp( match["created"] )
        var last_modified = OpenLibraryObject.OLTimeStamp( match["last_modified"] )
        if nil == created && nil != last_modified {
            
            created = last_modified
            
        } else if nil == last_modified && nil != created {
            
            last_modified = created
        }
        
        let type = match["type"] as? String ?? ""
        
        assert( nil != created )
        assert( nil != last_modified )
        assert( nil != revision )
        assert( nil != latest_revision )
        
        return ParsedSearchResult( key: key, name: name, personal_name: personal_name, birth_date: birth_date, death_date: death_date, photos: photos, links: links, bio: bioText, alternate_names: alternate_names, wikipedia: wikipedia, revision: revision!, latest_revision: latest_revision!, created: created, last_modified: last_modified, type: type )
    }
    
    // MARK: Initialization
    init(
        key: String,
        name: String,
        personal_name: String,
        birth_date: String,
        death_date: String,
        
        photos: [Int],                // transformable
        links: [[String: String]],    // transformable
        bio: String,
        alternate_names: [String],    // transformable
        
        wikipedia: String,
        
        revision: Int64,
        latest_revision: Int64,
        
        created: NSDate?,
        last_modified: NSDate?,
        
        type: String
        ) {
        
        self.key = key
        self.name = name
        self.personal_name = personal_name
        self.birth_date = birth_date
        self.death_date = death_date
        
        self.photos = photos
        self.links = links
        self.bio = bio
        self.alternate_names = alternate_names
        
        self.wikipedia = wikipedia
        
        self.revision = revision
        self.latest_revision = latest_revision
        
        self.created = created
        self.last_modified = last_modified
        
        self.type = type
    }
}

class OLAuthorDetail: OLManagedObject, CoreDataModelable {

    // MARK: Search Info
    struct SearchInfo {
        
        let objectID: NSManagedObjectID
        let key: String
    }
    
    lazy var deluxeData: [[DeluxeData]] = {
        
        let deluxeData = self.buildDeluxeData()
        
        return deluxeData
    }()
    
    lazy var hasDeluxeData: Bool = {
        
        return 1 < self.deluxeData.count || ( 1 == self.deluxeData.count && 1 < self.deluxeData[0].count )
    }()
    
    static let entityName = "AuthorDetail"
    
    class func parseJSON( parentObjectID: NSManagedObjectID, json: [String: AnyObject], moc: NSManagedObjectContext ) -> OLAuthorDetail? {
        
        guard let parsed = ParsedSearchResult.fromJSON( json ) else { return nil }
        
        guard let newObject =
            NSEntityDescription.insertNewObjectForEntityForName(
                OLAuthorDetail.entityName, inManagedObjectContext: moc
                ) as? OLAuthorDetail else { return nil }
        
        newObject.key = parsed.key
        newObject.name = parsed.name
        newObject.personal_name = parsed.personal_name
        newObject.birth_date = OpenLibraryObject.OLDateStamp( parsed.birth_date )
        newObject.death_date = OpenLibraryObject.OLDateStamp( parsed.death_date )
        
        newObject.photos = parsed.photos
        newObject.links = parsed.links
        newObject.bio = parsed.bio
        newObject.alternate_names = parsed.alternate_names
        
        newObject.revision = parsed.revision
        newObject.latest_revision = parsed.latest_revision
        
        newObject.created = OpenLibraryObject.OLTimeStamp( parsed.created )
        newObject.last_modified = OpenLibraryObject.OLTimeStamp( parsed.last_modified )
        
        newObject.type = parsed.type
        
        if let parent = moc.objectWithID( parentObjectID ) as? OLAuthorSearchResult {
            
            assert( parent.key == newObject.key )
            
            parent.toDetail = newObject
            parent.has_photos = newObject.hasImage
        }

        return newObject
    }
    
    override var heading: String {
        
        return self.name
    }
    
    override var defaultImageName: String {
        
        return "253-person.png"
    }
    
    var searchInfo: SearchInfo {
        
        return SearchInfo( objectID: self.objectID, key: self.key )
    }
    
    override var hasImage: Bool {
        
        return 0 < self.photos.count
    }

    override var firstImageID: Int {
        
        return 0 >= self.photos.count ? 0 : self.photos[0]
    }
    
    override func localURL( size: String, index: Int = 0 ) -> NSURL {
        
        return super.localURL( self.key, size: size, index: index )
    }
    
    // MARK: Deluxe Detail
    override func buildDeluxeData() -> [[DeluxeData]] {
        
        var deluxeData = [[DeluxeData]]()
        
        deluxeData.append( [DeluxeData( type: .header, caption: "Name", value: self.name )] )
        
        if !self.birth_date.isEmpty || !self.death_date.isEmpty {
            
            var newData = [DeluxeData]()
            if !self.birth_date.isEmpty {
                
                newData.append( DeluxeData( type: .inline, caption: "Born:", value: self.birth_date ) )
            }
            
            if !self.death_date.isEmpty {
                
                newData.append( DeluxeData( type: .inline, caption: "Died:", value: self.death_date ) )
            }
            
            deluxeData.append( newData )
        }
        
        if !self.bio.isEmpty {
            
            deluxeData.append( [DeluxeData( type: .block, caption: "Biography", value: self.bio )] )
        }
        
        if !self.links.isEmpty {
            
            var newData = [DeluxeData]()
            
            for link in self.links {
                
                if let title = link["title"], url = link["url"] {
                    newData.append( DeluxeData( type: .link, caption: title, value: url ) )
                    print( "\(title) \(url)" )
                }
            }
            
            if 0 < newData.count {
                
                deluxeData.append( newData )
            }
        }

        if !self.wikipedia.isEmpty {
            
            deluxeData[0].append( DeluxeData( type: .link, caption: "Wiikipedia", value: wikipedia ) )
        }
        
        if 1 < self.photos.count {
            
            var newData = [DeluxeData]()
            
            for index in 1..<self.photos.count {
                
                if -1 != photos[index] {

                    let value = localURL( "M", index: index ).absoluteString
                    newData.append(
                        DeluxeData( type: .authorImage, caption: String( photos[index] ), value: value )
                    )
                }
            }
            
            if 0 < newData.count {
                
                deluxeData.append( newData )
            }
        }
        
        return deluxeData
    }
    

}
