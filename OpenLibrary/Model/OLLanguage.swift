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

class OLLanguage: OLManagedObject {

// Insert code here to add functionality to your managed object subclass
    static let entityName = "Language"
    
    class func parseJSON(_ sequence: Int64, index: Int64, json: [String: AnyObject], moc: NSManagedObjectContext ) -> OLLanguage? {
        
        guard let parsed = ParsedSearchResult( json: json ) else { return nil }
        
        moc.mergePolicy = NSOverwriteMergePolicy
        
        var newObject: OLLanguage?
        
        newObject = findObject( parsed.key, entityName: entityName, moc: moc )
        if nil == newObject {
            newObject =
                NSEntityDescription.insertNewObject(
                        forEntityName: OLLanguage.entityName, into: moc
                    ) as? OLLanguage
        }
        
        if let newObject = newObject {

            newObject.sequence = sequence
            newObject.index = index
            
            newObject.retrieval_date = Date()
        
            newObject.key = parsed.key
        
            newObject.code = parsed.code
            newObject.name = parsed.name
        }
        
        return newObject
    }
}

extension OLLanguage {

    class func retrieveLanguages( _ operationQueue: PSOperationQueue, coreDataStack: OLDataStack ) {
        
        let context = coreDataStack.newChildContext( name: "findLanguages" )
        
        context.perform {
        
            let languageCount = loadLanguageLookup( context )
            if 0 == languageCount {
        
                let operation = LanguagesGetOperation( coreDataStack: coreDataStack ) {
                    
                    context.perform {
                        _ = loadLanguageLookup( context )
                    }
                }
                operationQueue.addOperation( operation )
            }
        }
    }
    
    class func loadLanguageLookup( _ moc: NSManagedObjectContext ) -> Int {
        
        var loadedLanguages = [String: String]()

        let fetchRequest: NSFetchRequest<OLLanguage> = OLLanguage.buildFetchRequest()
        
        do {
            let languages = try moc.fetch( fetchRequest )

            for language in languages {
                
                let key = language.key
                let name = language.name
                
                loadedLanguages[key] = name
            }
        }
        catch {
            print( "\(error)" )
        }
        
        OLManagedObject.saveLoadedLanguages( loadedLanguages )

        return loadedLanguages.count
    }

}

extension OLLanguage {

    class func buildFetchRequest() -> NSFetchRequest< OLLanguage > {
        
        return NSFetchRequest( entityName: OLLanguage.entityName )
    }
}
