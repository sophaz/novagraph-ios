//
//  FetchOrCreatable.swift
//  Novagraph
//
//  Created by Sophie on 12/1/18.
//

import Foundation
import UIKit
import CoreData

protocol HasID {
    var id: String { get set }
}

protocol Parseable {
    func parse(data: [String: Any])
}

protocol FetchOrCreatable: class, HasID, Parseable {

    associatedtype T: NSManagedObject, HasID, Parseable
    static func fetch(with ID: String) -> T?
    static func fetchOrCreate(with dict: [String: Any]) -> T?
    static func fetchOrCreate(with ID: String) -> T
}

extension FetchOrCreatable {

    static func fetch(with ID: String) -> T? {
        let className = String(describing: type(of: self)).split(separator: ".").first ?? ""

        let request = NSFetchRequest<T>(entityName: String(className))
        request.predicate = NSPredicate(format: "id == %@", ID)
        let context = CoreDataManager.shared.context
        let fetchedObjects = try! context?.fetch(request)
        if let first = fetchedObjects?.first {
            return first
        }
        return nil
    }

    @discardableResult static func fetchOrCreate(with ID: String) -> T {
        if let object = self.fetch(with: ID) {
            return object
        } else {
            let className = String(describing: type(of: self)).split(separator: ".").first ?? ""
            var newT = NSEntityDescription.insertNewObject(forEntityName: String(className), into: CoreDataManager.shared.context) as! T
            newT.id = ID

            return newT
        }
    }

    @discardableResult static func fetchOrCreate(with dict: [String: Any]) -> T? {
        if let id = dict["id"] as? String {
            let object = self.fetchOrCreate(with: id)
            object.parse(data: dict)
            return object
        }
        return nil
    }

    static func createNew() -> T {
        let className = String(describing: type(of: self)).split(separator:".").first ?? ""
        let newT = NSEntityDescription.insertNewObject(forEntityName: String(className), into: CoreDataManager.shared.context) as! T
        return newT
    }
}
