//
//  Entity.swift
//  Alamofire
//
//  Created by Christopher Wilson on 2/7/19.
//

import CoreData

open class Entity: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var type: String
    
    open func parse(dict: [String: Any]) {
        if let id = dict["id"] as? String {
            self.id = id
        }
        if let type = dict["type"] as? String {
            self.type = type
        }
    }
}
