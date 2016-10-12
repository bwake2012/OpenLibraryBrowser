//
//  OLAuthorDetail.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/1/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

import BNRCoreDataStack

let kAuthorsPrefix = "/authors/"
let kAuthorType    = "/type/author"

class OLAuthorDetail: OLManagedObject, CoreDataModelable {

    // MARK: Search Info
    struct SearchInfo {
        
        let objectID: NSManagedObjectID
        let key: String
    }
    
    static let entityName = "AuthorDetail"
    
    class func parseJSON( parentObjectID: NSManagedObjectID?, json: [String: AnyObject], moc: NSManagedObjectContext ) -> OLAuthorDetail? {
        
        guard let parsed = ParsedFromJSON.fromJSON( json ) else { return nil }
        
        moc.mergePolicy = NSOverwriteMergePolicy
        let newObject: OLAuthorDetail? =
                NSEntityDescription.insertNewObjectForEntityForName(
                    OLAuthorDetail.entityName, inManagedObjectContext: moc
                ) as? OLAuthorDetail
        
        if let newObject = newObject {
            
            newObject.retrieval_date = NSDate()
            newObject.provisional_date = nil
            newObject.is_provisional = false

            newObject.populateObject( parsed )
            
            newObject.addToAuthorCache( newObject.key, authorName: newObject.name )
        }
       
        return newObject
    }
    
    class func saveProvisionalAuthor( authorIndex: Int, parsed: OLGeneralSearchResult.ParsedFromJSON, moc: NSManagedObjectContext ) -> OLAuthorDetail? {
        
        var newObject: OLAuthorDetail?
        
        if authorIndex < parsed.author_key.count {
            
            newObject = findObject( parsed.author_key[authorIndex], entityName: entityName, moc: moc )
            if nil == newObject {
                
                newObject =
                    NSEntityDescription.insertNewObjectForEntityForName(
                        OLAuthorDetail.entityName, inManagedObjectContext: moc
                    ) as? OLAuthorDetail
                
                if let newObject = newObject {
                    
                    newObject.retrieval_date = NSDate()
                    newObject.provisional_date = NSDate()
                    newObject.is_provisional = true
                    
                    newObject.key = parsed.author_key[authorIndex]
                    newObject.type = "/type/author"
                    
                    newObject.name = parsed.author_name[authorIndex]
                    newObject.photos = []
                    
                    newObject.links = [[:]]
                    
                    newObject.bio = ""
                    newObject.alternate_names = []
                    
                    newObject.wikipedia = ""
                    
                    newObject.revision = 0
                    newObject.latest_revision = 0

                    newObject.addToAuthorCache( newObject.key, authorName: newObject.name )
                }
            }
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
    
    override var isProvisional: Bool {
        
        return is_provisional
    }
    
    override var hasImage: Bool {
        
        return 0 < self.photos.count && 0 < photos[0]
    }

    override var firstImageID: Int {
        
        return !hasImage ? 0 : self.photos[0]
    }
    
    override var imageType: String { return "a" }
    
    override func imageID( index: Int ) -> Int {
        
        return !hasImage ? 0 : self.photos[index]
    }
    
    override func localURL( size: String, index: Int = 0 ) -> NSURL {
        
        return super.localURL( self.photos[index], size: size )
    }
    
    override func populateObject( parsed: OpenLibraryObject ) {

        self.retrieval_date = NSDate()
        
        if let parsed = parsed as? ParsedFromJSON {
            
            self.key = parsed.key
            self.name = parsed.name
            self.personal_name = parsed.personal_name
            self.birth_date = OpenLibraryObject.OLDateStamp( parsed.birth_date )
            self.death_date = OpenLibraryObject.OLDateStamp( parsed.death_date )
            
            self.photos = parsed.photos
            self.links = parsed.links
            self.bio = parsed.bio
            self.alternate_names = parsed.alternate_names
            self.wikipedia = parsed.wikipedia
            
            self.revision = parsed.revision
            self.latest_revision = parsed.latest_revision
            
            self.created = parsed.created
            self.last_modified = parsed.last_modified
            
            self.type = parsed.type
        }
    }
 
    // MARK: Deluxe Detail
    override func buildDeluxeData() -> [[DeluxeData]] {
        
        var deluxeData = [[DeluxeData]]()
        
        deluxeData.append( [DeluxeData( type: .heading, caption: "Name", value: self.name )] )
        
        if hasImage {

            let value = localURL( "M", index: 0 ).absoluteString
            let extraValue = localURL( "L", index: 0 ).absoluteString
            let deluxeItem =
                DeluxeData(
                        type: .imageAuthor,
                        caption: String( firstImageID ),
                        value: value,
                        extraValue: extraValue
                    )

            deluxeData.append( [deluxeItem] )
        }
        
        if !self.birth_date.isEmpty || !self.death_date.isEmpty {
            
            var newData = [DeluxeData]()
            if !self.birth_date.isEmpty {
                
                newData.append( DeluxeData( type: .block, caption: "Born", value: self.birth_date ) )
            }
            
            if !self.death_date.isEmpty {
                
                newData.append( DeluxeData( type: .block, caption: "Died", value: self.death_date ) )
            }
            
            deluxeData.append( newData )
        }
        
        if !self.bio.isEmpty {

            let bio = self.bio
            let fancyOutput = fancyMarkdown.transform( bio )
            
            deluxeData.append( [DeluxeData( type: .html, caption: "Biography", value: fancyOutput )] )
        }
        
        if !self.links.isEmpty {
            
            var newData = [DeluxeData]()
            
            for link in self.links {
                
                if let title = link["title"], url = link["url"] {
                    newData.append( DeluxeData( type: .link, caption: title, value: url ) )
//                    print( "\(title) \(url)" )
                }
            }
            
            if 0 < newData.count {
                
                deluxeData.append( newData )
            }
        }

        if !self.wikipedia.isEmpty {
            
            deluxeData[0].append( DeluxeData( type: .link, caption: "Wikipedia", value: wikipedia ) )
        }
        
        if 1 < self.photos.count {
            
            let newData = [DeluxeData]()
            
            for index in 1..<self.photos.count {
                
                if -1 != photos[index] {

                    let value = localURL( "M", index: index ).absoluteString
                    let extraValue = localURL( "L", index: index ).absoluteString
                    let deluxeItem =
                        DeluxeData(
                            type: .imageAuthor,
                            caption: String( imageID( index ) ),
                            value: value,
                            extraValue: extraValue
                    )
                    
                    deluxeData.append( [deluxeItem] )
                }
            }
            
            if 0 < newData.count {
                
                deluxeData.append( newData )
            }
        }
        
        let dateFormatter = NSDateFormatter()
        
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .MediumStyle
        
        var newData = [DeluxeData]()
        
        if let created = created {
            
            newData.append(
                DeluxeData(
                    type: .inline,
                    caption: "Created",
                    value: dateFormatter.stringFromDate( created )
                )
            )
        }
        
        if let last_modified = last_modified {
            
            newData.append(
                DeluxeData(
                    type: .inline,
                    caption: "Last Modified",
                    value: dateFormatter.stringFromDate( last_modified )
                )
            )
        }
        
        newData.append(
            DeluxeData(type: .inline, caption: "Revision", value: String( revision ) )
        )
        
        newData.append(
            DeluxeData(type: .inline, caption: "Latest Revision", value: String( latest_revision ) )
        )
        
        newData.append(
            DeluxeData( type: .inline, caption: "Type", value: type )
        )

        newData.append(
            DeluxeData( type: .inline, caption: "OLID", value: key )
        )
        
        newData.append(
            DeluxeData(
                type: .inline,
                caption: "Retrieved",
                value: dateFormatter.stringFromDate( retrieval_date )
            )
        )
        
        newData.append(
            DeluxeData(type: .inline, caption: "", value: isProvisional ? "Provisional" : "Actual" )
        )
        
        deluxeData.append( newData )
        
        return deluxeData
    }
}

extension OLAuthorDetail {
    
    /// An object to represent a parsed author search result.
    class ParsedFromJSON: OpenLibraryObject {
        
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
        
        class func fromJSON ( json: [String: AnyObject] ) -> ParsedFromJSON? {
            
            guard let key = json["key"] as? String else { return nil }
            
            guard let name = json["name"] as? String else { return nil }
            
            let personal_name = json["personal_name"] as? String ?? ""
            
            let birth_date = OpenLibraryObject.OLDateStamp( json["birth_date"] )
            let death_date = OpenLibraryObject.OLDateStamp( json["death_date"] )
            
            let photos = OpenLibraryObject.OLIntArray( json["photos"] )
            
            let links = OpenLibraryObject.OLLinks( json )
            
            let bioText = OpenLibraryObject.OLText( json["bio"] )
            
            let alternate_names = OpenLibraryObject.OLStringArray( json["alternate_names"] )
            
            let wikipedia = OpenLibraryObject.OLString( json["wikipedia"] )
            
            var revision = json["revision"] as? Int64
            var latest_revision = json["latest_revision"] as? Int64
            if nil == revision && nil != latest_revision {
                
                revision = latest_revision
                
            } else if nil == latest_revision && nil != revision {
                
                latest_revision = revision
                
            } else if nil == revision && nil == latest_revision {
                
                revision = Int64( 0 )
                latest_revision = Int64( 0 )
                
            }
            
            var created = OpenLibraryObject.OLTimeStamp( json["created"] )
            var last_modified = OpenLibraryObject.OLTimeStamp( json["last_modified"] )
            if nil == created && nil != last_modified {
                
                created = last_modified
                
            } else if nil == last_modified && nil != created {
                
                last_modified = created
            }
            
            let type = OpenLibraryObject.OLKeyedValue( json["type"], key: "key" )
            
            assert( nil != created )
            assert( nil != last_modified )
            assert( nil != revision )
            assert( nil != latest_revision )
            
            return ParsedFromJSON( key: key, name: name, personal_name: personal_name, birth_date: birth_date, death_date: death_date, photos: photos, links: links, bio: bioText, alternate_names: alternate_names, wikipedia: wikipedia, revision: revision!, latest_revision: latest_revision!, created: created, last_modified: last_modified, type: type )
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
}

extension OLAuthorDetail {
    
    class func saveProvisionalAuthor( authorIndex: Int, parsed: OLGeneralSearchResult, moc: NSManagedObjectContext ) -> OLAuthorDetail? {
        
        var newObject: OLAuthorDetail?
        
        if authorIndex < parsed.author_key.count {
            
            newObject = findObject( parsed.author_key[authorIndex], entityName: entityName, moc: moc )
            if nil == newObject {
                
                newObject =
                    NSEntityDescription.insertNewObjectForEntityForName(
                        OLAuthorDetail.entityName, inManagedObjectContext: moc
                    ) as? OLAuthorDetail
                
                if let newObject = newObject {
                    
                    newObject.retrieval_date = NSDate()
                    newObject.provisional_date = NSDate()
                    newObject.is_provisional = true
                    
                    newObject.key = parsed.author_key[authorIndex]
                    newObject.type = "/type/author"
                    
                    newObject.name = parsed.author_name[authorIndex]
                    newObject.photos = []
                    
                    newObject.links = [[:]]
                    
                    newObject.bio = ""
                    newObject.alternate_names = []
                    
                    newObject.wikipedia = ""
                    
                    newObject.revision = 0
                    newObject.latest_revision = 0
                }
            }
        }
        
        return newObject
    }
    
}

