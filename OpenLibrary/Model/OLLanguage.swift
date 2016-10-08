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
import PSOperations

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
        
        moc.mergePolicy = NSOverwriteMergePolicy
        
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
            
            newObject.retrieval_date = NSDate()
        
            newObject.key = parsed.key
        
            newObject.code = parsed.code
            newObject.name = parsed.name
        }
        
        return newObject
    }
    
    class func retrieveLanguages( operationQueue: OperationQueue, coreDataStack: CoreDataStack ) {
        
        let context = coreDataStack.newChildContext( name: "findLanguages" )
        
        context.performBlock {
        
            let languageCount = loadLanguageLookup( context )
            if 0 == languageCount {
        
                let operation = LanguagesGetOperation( coreDataStack: coreDataStack ) {
                    
                    context.performBlock {
                        loadLanguageLookup( context )
                    }
                }
                operationQueue.addOperation( operation )
            }
        }
    }
    
    class func loadLanguageLookup( moc: NSManagedObjectContext ) -> Int {
        
        var loadedLanguages = [String: String]()

        let fetchRequest = NSFetchRequest( entityName: OLLanguage.entityName )
        
        do {
            let objects = try moc.executeFetchRequest( fetchRequest )

            for object in objects {
                
                if let language = object as? OLLanguage {
                    
                    let code = language.code
                    let name = language.name
                    
                    loadedLanguages[code] = name
                }
            }
        }
        catch {
            print( "\(error)" )
        }
        
        OLManagedObject.saveLoadedLanguages( loadedLanguages )

        return OLManagedObject.languageLookup.count
    }

}
