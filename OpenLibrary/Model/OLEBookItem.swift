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

class OLEBookItem: OLManagedObject {

// Insert code here to add functionality to your managed object subclass
    struct SearchInfo {
        
        let objectID: NSManagedObjectID
        let key: String
    }
    
    static let entityName = "EBookItem"
    
    class func parseJSON( jsonItem: [String: AnyObject], jsonDetail: [String: AnyObject], moc: NSManagedObjectContext ) -> OLEBookItem? {
        
        guard let parsed = ParsedFromJSON.fromJSON( jsonItem, details: jsonDetail ) else { return nil }

        var newObject: OLEBookItem? = findObject( parsed.editionKey, entityName: OLEBookItem.entityName, keyFieldName: "editionKey", moc: moc )
        if nil == newObject {
            newObject =
                NSEntityDescription.insertNewObject(
                        forEntityName: OLEBookItem.entityName, into: moc
                    ) as? OLEBookItem
        }

        if let newObject = newObject {

            newObject.retrieval_date = Date()

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
            
            if nil == newObject.editionDetail {

                newObject.editionDetail =
                    OLEditionDetail.saveProvisionalEdition( parsed: parsed, moc: moc )
            }
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
    
    override func imageID( _ index: Int ) -> Int {
        
        return index > 0 ? 0 : Int( cover_id )
    }
    
    override func localURL( _ size: String, index: Int = 0 ) -> URL {
        
        return super.localURL( firstImageID, size: size )
    }
    
    @discardableResult func matchingEdition() -> OLEditionDetail? {
        
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

extension OLEBookItem {

    class ParsedFromJSON: OpenLibraryObject {
        
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
        
        let author_keys: [String]
        let author_names: [String]
        
        let by_statement: String
        
        let title: String
        let subtitle: String
        
        let languages: [String]
        
        let isbn_10: [String]
        
        // MARK: Initialization
        
        class func fromJSON( _ item: [String: AnyObject], details: [String: AnyObject] ) -> ParsedFromJSON? {
            
            let status       = item["status"] as? String ?? ""
            var workKey      = item["ol-work-id"] as? String ?? ""
            if !workKey.hasPrefix( kWorksPrefix ) {
                workKey = kWorksPrefix + workKey
            }
            var editionKey   = item["ol-edition-id"] as? String ?? ""
            if !editionKey.hasPrefix( kEditionsPrefix ) {
                editionKey = kEditionsPrefix + editionKey
            }
            let publish_date = item["publishDate"] as? String ?? "not recorded"
            let itemURL      = item["itemURL"] as? String ?? ""
            var eBookKey = ""
            if !itemURL.isEmpty {
                if let url = URL( string: itemURL ) {
                    
                    eBookKey = url.lastPathComponent
                }
            }
            let enumcron     = item["enumcron"] as? Bool ?? false
            let contributor  = item["contributor"] as? String ?? ""
            let fromRecord   = item["fromRecord"] as? String ?? ""
            let match        = item["match"] as? String ?? ""
            
            var cover_id = Int64( 0 )
            if let coverDict: [String: String] = item["cover"] as? [String: String] {
                
                for entry in coverDict {
                    
                    if entry.0 == "small" || entry.0 == "large" || entry.0 == "medium" {
                        
                        if let url = URL( string: entry.1 ) {
                            
                            let last = url.lastPathComponent
                            
                            let parts = last.characters.split( separator: "-" ).map( String.init )
                            
                            if let id = Int64( parts[0] ) {
                                cover_id = id
                                break
                            }
                        }
                    }
                }
            }
            
            // MARK: editionDetail
            
            guard let editionDetail = details["details"] as? [String: AnyObject] else {
                
                return nil
            }
            
            var author_names: [String] = []
            var author_keys: [String] = []
            if let authorList = editionDetail["authors"] as? [[String: String]] {
                
                for authorEntry in authorList {
                    
                    if let name = authorEntry["name"], let key = authorEntry["key"] {
                        
                        author_names.append( name )
                        author_keys.append(  key )
                    }
                }
            }
            
            let by_statement = editionDetail["by_statement"] as? String ?? ""
            
            let title = editionDetail["title"] as? String ?? ""
            let subtitle = editionDetail["subtitle"] as? String ?? ""
            
            var languages = [String]()
            if let languageList = editionDetail["languages"] as? [[String: String]] {
                
                for languageEntry in languageList {
                    
                    if let language = languageEntry["key"] {
                        
                        languages.append( language )
                    }
                }
            }
            
            let isbn_10 = editionDetail["isbn_10"] as? [String] ?? []
            
            return ParsedFromJSON( status: status, workKey: workKey, editionKey: editionKey, eBookKey: eBookKey, cover_id: cover_id, publish_date: publish_date, itemURL: itemURL, enumcron: enumcron, contributor: contributor, fromRecord: fromRecord, match: match,
                                   author_keys: author_keys, author_names: author_names,
                                   by_statement: by_statement,
                                   title: title, subtitle: subtitle,
                                   languages: languages,
                                   isbn_10: isbn_10
            )
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
            match: String,
            
            author_keys: [String],
            author_names: [String],
            by_statement: String,
            title: String,
            subtitle: String,
            languages: [String],
            isbn_10: [String]
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
            
            self.author_keys = author_keys
            self.author_names = author_names
            self.by_statement = by_statement
            self.title = title
            self.subtitle = subtitle
            self.languages = languages
            self.isbn_10 = isbn_10
        }
    }
}

extension OLEBookItem {
    
    class func buildFetchRequest() -> NSFetchRequest< OLEBookItem > {
        
        return NSFetchRequest( entityName: OLEBookItem.entityName )
    }
}

