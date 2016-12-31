//
//  OLEBookItem+CoreDataProperties.swift
//  
//
//  Created by Bob Wakefield on 5/12/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension OLEBookItem {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<OLEBookItem> {
        return NSFetchRequest<OLEBookItem>( entityName: OLEBookItem.entityName )
    }
    
    @NSManaged var retrieval_date: Date

    @NSManaged var status: String
    @NSManaged var workKey: String
    @NSManaged var editionKey: String
    @NSManaged var eBookKey: String
    @NSManaged var cover_id: Int64
    @NSManaged var publish_date: String
    @NSManaged var itemURL: String
    @NSManaged var enumcron: Bool
    @NSManaged var contributor: String
    @NSManaged var fromRecord: String
    @NSManaged var match: String

    @NSManaged var editionDetail: OLEditionDetail?
}
