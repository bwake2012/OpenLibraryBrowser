//
//  OLLanguage+CoreDataProperties.swift
//  
//
//  Created by Bob Wakefield on 4/16/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension OLLanguage {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<OLLanguage> {
        return NSFetchRequest<OLLanguage>( entityName: OLLanguage.entityName )
    }
    
    @NSManaged var sequence: Int64
    @NSManaged var index: Int64
    @NSManaged var key: String
    @NSManaged var code: String
    @NSManaged var name: String
    @NSManaged var retrieval_date: Date

}
