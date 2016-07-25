//
//  OLEBookItem.swift
//  
//
//  Created by Bob Wakefield on 5/12/16.
//
//

import Foundation
import CoreData

import BNRCoreDataStack

private class ParsedSearchResult: OpenLibraryObject {
    
    let status: String
    let workKey: String
    let editionKey: String
    let eBookKey: String
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
        var workKey      = json["ol-work-id"] as? String ?? ""
        if !workKey.hasPrefix( kWorksPrefix ) {
            workKey = kWorksPrefix + workKey
        }
        var editionKey   = json["ol-edition-id"] as? String ?? ""
        if !editionKey.hasPrefix( kEditionsPrefix ) {
            editionKey = kEditionsPrefix + editionKey
        }
        let publish_date = json["publishDate"] as? String ?? "not recorded"
        let itemURL      = json["itemURL"] as? String ?? ""
        var eBookKey = ""
        if !itemURL.isEmpty {
            if let url = NSURL( string: itemURL ) {
            
                if let lastComponent = url.lastPathComponent {
                    
                    eBookKey = lastComponent
                }
            }
        }
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
                
        return ParsedSearchResult( status: status, workKey: workKey, editionKey: editionKey, eBookKey: eBookKey, cover_id: cover_id, publish_date: publish_date, itemURL: itemURL, enumcron: enumcron, contributor: contributor, fromRecord: fromRecord, match: match )
    }
    
    init(
        status: String,
        workKey: String,
        editionKey: String,
        eBookKey: String,
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
        self.eBookKey = eBookKey
        self.cover_id = cover_id
        self.publish_date = publish_date
        self.itemURL = itemURL
        self.enumcron = enumcron
        self.contributor = contributor
        self.fromRecord = fromRecord
        self.match = match
    }
}

class OLEBookItem: OLManagedObject, CoreDataModelable {

// Insert code here to add functionality to your managed object subclass
    struct SearchInfo {
        
        let objectID: NSManagedObjectID
        let key: String
    }
    
    static let entityName = "EBookItem"
    
    class func parseJSON( json: [String: AnyObject], moc: NSManagedObjectContext ) -> OLEBookItem? {
        
        guard let parsed = ParsedSearchResult.fromJSON( json ) else { return nil }

        var newObject: OLEBookItem? = findObject( parsed.eBookKey, entityName: OLEBookItem.entityName, keyFieldName: "eBookKey", moc: moc )
        if nil == newObject {
            newObject =
                NSEntityDescription.insertNewObjectForEntityForName(
                        OLEBookItem.entityName, inManagedObjectContext: moc
                    ) as? OLEBookItem
        }

        if let newObject = newObject {
            
            newObject.retrieval_date = NSDate()

            newObject.status       = parsed.status
            newObject.workKey      = parsed.workKey
            newObject.editionKey   = parsed.editionKey
            newObject.eBookKey     = parsed.eBookKey
            newObject.cover_id     = parsed.cover_id
            newObject.publish_date = parsed.publish_date
            newObject.itemURL      = parsed.itemURL
            newObject.enumcron     = parsed.enumcron
            newObject.contributor  = parsed.contributor
            newObject.fromRecord   = parsed.fromRecord
            newObject.match        = parsed.match
            
            newObject.editionDetail = nil
        }
        
        return newObject
    }
    
    override var hasImage: Bool {
        
        return 0 < cover_id
    }
    
    override var firstImageID: Int {
        
        return Int( cover_id )
    }
    
    override var imageType: String { return "b" }
    
    override func imageID( index: Int ) -> Int {
        
        return index > 0 ? 0 : Int( cover_id )
    }
    
    override func localURL( size: String, index: Int = 0 ) -> NSURL {
        
        return super.localURL( self.editionKey, size: size, index: index )
    }
    
    var editionDetail: OLEditionDetail?

    func matchingEdition() -> OLEditionDetail? {
        
        if nil == editionDetail {

            if let moc = self.managedObjectContext {
                
                if let editionDetail: OLEditionDetail =
                    OLEditionDetail.findObject( editionKey, entityName: OLEditionDetail.entityName, moc: moc ) {
                    
                    self.editionDetail = editionDetail
                }
            }
        }
        
        return editionDetail
    }
}
