//
//  OLLanguage.swift
//  
//
//  Created by Bob Wakefield on 4/16/16.
//
//

import Foundation
import CoreData

import BNRCoreDataStack

private class ParsedSearchResult: OpenLibraryObject {
    
    // MARK: Properties.
    
    let key: String
    
    let code: String
    let name: String
    
    // MARK: Initialization
    
    init(
        key: String,
        code: String,
        name: String
        ) {
        self.key = key
        
        self.code = code
        self.name = name
    }
    
    convenience init?( match: [String: AnyObject] ) {
        
        guard let key = match["key"] as? String else { return nil }
        
        guard let code = match["code"] as? String else { return nil }
        
        guard let name = match["name"] as? String else { return nil }
        
        self.init(
            key: key,
            code: code,
            name: name
        )
        
    }
}

class OLLanguage: NSManagedObject, CoreDataModelable {

// Insert code here to add functionality to your managed object subclass
    static let entityName = "Language"
    
    class func parseJSON(sequence: Int64, index: Int64, match: [String: AnyObject], moc: NSManagedObjectContext ) -> OLLanguage? {
        
        guard let parsed = ParsedSearchResult( match: match ) else { return nil }
        
        guard let newObject =
            NSEntityDescription.insertNewObjectForEntityForName(
                OLLanguage.entityName, inManagedObjectContext: moc
                ) as? OLLanguage else { return nil }
        
        newObject.sequence = sequence
        newObject.index = index
        
        newObject.key = parsed.key
        
        newObject.code = parsed.code
        newObject.name = parsed.name
        
        return newObject
    }
    

}
