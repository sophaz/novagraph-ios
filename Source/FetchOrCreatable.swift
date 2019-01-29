//
//  FetchOrCreatable.swift
//  Novagraph
//
//  Created by Sophie on 12/1/18.
//

import Foundation
import UIKit
import CoreData

public protocol HasID {
    var id: String { get set }
}

public protocol Parseable {
    func parse(data: [String: Any])
}

public protocol FetchOrCreatable: class, HasID, Parseable {

    associatedtype T: NSManagedObject, HasID, Parseable
    static func fetch(with ID: String) -> T?
    static func fetchOrCreate(with dict: [String: Any]) -> T?
    static func fetchOrCreate(with ID: String) -> T
    static func fetchOrCreateObjects(from data: Any?) -> [T]

}

public extension FetchOrCreatable {

    public static func fetch(with ID: String) -> T? {
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

    @discardableResult public static func fetchOrCreate(with ID: String) -> T {
        if let object = self.fetch(with: ID) {
            return object
        } else {
            let className = String(describing: type(of: self)).split(separator: ".").first ?? ""
            var newT = NSEntityDescription.insertNewObject(forEntityName: String(className), into: CoreDataManager.shared.context) as! T
            newT.id = ID

            return newT
        }
    }

    @discardableResult public static func fetchOrCreate(with dict: [String: Any]) -> T? {
        if let id = dict["id"] as? String {
            let object = self.fetchOrCreate(with: id)
            object.parse(data: dict)
            return object
        }
        return nil
    }

    @discardableResult public static func fetchOrCreateObjects(from data: Any?) -> [T] {
        var objects: [T] = []
        guard let dict = data as? [String: Any], let objectsDict = dict["objects"] as? [String: Any] else { return [] }
        for (_, value) in objectsDict {
            guard let objectDict = value as? [String: Any] else { continue }
            if let myObject = self.fetchOrCreate(with: objectDict) {
                objects.append(myObject)
            }
        }
        return objects
    }

    public static func createNew() -> T {
        let className = String(describing: type(of: self)).split(separator:".").first ?? ""
        let newT = NSEntityDescription.insertNewObject(forEntityName: String(className), into: CoreDataManager.shared.context) as! T
        return newT
    }

}
