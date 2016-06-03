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
    
    convenience init?( json: [String: AnyObject] ) {
        
        guard let key = json["key"] as? String else { return nil }
        
        guard let code = json["code"] as? String else { return nil }
        
        guard let name = json["name"] as? String else { return nil }
        
        self.init(
            key: key,
            code: code,
            name: name
        )
        
    }
}

class OLLanguage: OLManagedObject, CoreDataModelable {

// Insert code here to add functionality to your managed object subclass
    static let entityName = "Language"
    
    class func parseJSON(sequence: Int64, index: Int64, json: [String: AnyObject], moc: NSManagedObjectContext ) -> OLLanguage? {
        
        guard let parsed = ParsedSearchResult( json: json ) else { return nil }
        
        var newObject: OLLanguage?
        
        newObject = findObject( parsed.key, entityName: entityName, moc: moc )
        if nil == newObject {
            newObject =
                NSEntityDescription.insertNewObjectForEntityForName(
                        OLLanguage.entityName, inManagedObjectContext: moc
                    ) as? OLLanguage
        }
        
        if let newObject = newObject {

            newObject.sequence = sequence
            newObject.index = index
        
            newObject.key = parsed.key
        
            newObject.code = parsed.code
            newObject.name = parsed.name
        }
        
        return newObject
    }
    

}
