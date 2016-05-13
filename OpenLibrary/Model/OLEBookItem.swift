//
//  OLEBookItem.swift
//  
//
//  Created by Bob Wakefield on 5/12/16.
//
//

import Foundation
import CoreData

private class ParsedSearchResult: OpenLibraryObject {
    
    let status: String
    let workKey: String
    let editionKey: String
    let cover_id: Int64
    let publish_date: String
    let itemURL: String
    let enumcron: Bool
    let contributor: String
    let fromRecord: String
    let match: String
    
    // MARK: Initialization
    
    class func fromJSON( json: [String: AnyObject] ) -> ParsedSearchResult? {
        
        let status       = json["status"] as? String ?? ""
        let workKey      = json["ol-work-id"] as? String ?? ""
        let editionKey   = json["ol-edition-id"] as? String ?? ""
        let publish_date = json["publishDate"] as? String ?? ""
        let itemURL      = json["itemURL"] as? String ?? ""
        let enumcron     = json["enumcron"] as? Bool ?? false
        let contributor  = json["contributor"] as? String ?? ""
        let fromRecord   = json["fromRecord"] as? String ?? ""
        let match        = json["match"] as? String ?? ""

        var cover_id = Int64( 0 )
        if let coverDict: [String: String] = json["cover"] as? [String: String] {
            
            for entry in coverDict {
                
                if entry.0 == "small" || entry.0 == "large" || entry.0 == "medium" {
                    
                    if let url = NSURL( string: entry.1 ) {
                        
                        if let last = url.lastPathComponent {
                            let parts = last.characters.split( "-" ).map( String.init )
                            
                            if let id = Int64( parts[0] ) {
                                cover_id = id
                                break
                            }
                        }
                    }
                }
            }
        }
                
        return ParsedSearchResult( status: status, workKey: workKey, editionKey: editionKey, cover_id: cover_id, publish_date: publish_date, itemURL: itemURL, enumcron: enumcron, contributor: contributor, fromRecord: fromRecord, match: match )
    }
    
    init(
        status: String,
        workKey: String,
        editionKey: String,
        cover_id: Int64,
        publish_date: String,
        itemURL: String,
        enumcron: Bool,
        contributor: String,
        fromRecord: String,
        match: String
        ) {
        
        self.status = status
        self.workKey = workKey
        self.editionKey = editionKey
        self.cover_id = cover_id
        self.publish_date = publish_date
        self.itemURL = itemURL
        self.enumcron = enumcron
        self.contributor = contributor
        self.fromRecord = fromRecord
        self.match = match
    }
}

class OLEBookItem: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    struct SearchInfo {
        
        let objectID: NSManagedObjectID
        let key: String
    }
    
    static let entityName = "EBookItem"
    
    class func parseJSON( json: [String: AnyObject], moc: NSManagedObjectContext ) -> OLEBookItem? {
        
        guard let parsed = ParsedSearchResult.fromJSON( json ) else { return nil }

        guard let newObject =
            NSEntityDescription.insertNewObjectForEntityForName(
                    OLEBookItem.entityName, inManagedObjectContext: moc
                ) as? OLEBookItem else { return nil }

        newObject.status       = parsed.status
        newObject.workKey      = parsed.workKey
        newObject.editionKey   = parsed.editionKey
        newObject.cover_id     = parsed.cover_id
        newObject.publish_date = parsed.publish_date
        newObject.itemURL      = parsed.itemURL
        newObject.enumcron     = parsed.enumcron
        newObject.contributor  = parsed.contributor
        newObject.fromRecord   = parsed.fromRecord
        newObject.match        = parsed.match

        return newObject
    }
}
