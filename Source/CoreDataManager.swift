//
//  CoreDataManager.swift
//  Pods-Novagraph_Example
//
//  Created by Sophie on 12/1/18.
//

import Foundation
import UIKit
import CoreData

public class CoreDataManager: NSObject {

    public var context: NSManagedObjectContext!
    public static let shared: CoreDataManager = CoreDataManager()
    public static var containerName: String!

    public class func setUpCoreDataStack(retry: Bool = false) {
        let container = NSPersistentContainer(name: self.containerName)
        container.loadPersistentStores { (_, error) in
            guard error == nil else {
                if retry {
                    self.deleteStore()
                    self.setUpCoreDataStack(retry: false)
                } else {
                    NSLog("Failed to load core data stack!")
                }
                return
            }
            shared.context = container.viewContext
            NSLog("Loaded store!")
        }
    }

    public class func resetStore() {
        let container = NSPersistentContainer(name: self.containerName)
        container.loadPersistentStores { (store, _) in
            let coordinator = container.persistentStoreCoordinator
            let stores = coordinator.persistentStores
            for store in stores {
                if let url = store.url {
                    try! FileManager.default.removeItem(atPath: url.path)
                    try! coordinator.destroyPersistentStore(at: url, ofType: store.type, options: nil)
                }
            }
        }
        self.setUpCoreDataStack()
    }

    class func deleteStore() {
        var url = NSPersistentContainer.defaultDirectoryURL()
        url.appendPathComponent(self.containerName)
        url.appendPathExtension("sqlite")
        try? FileManager.default.removeItem(at: url)
    }

}

extension CoreDataManager {

    public static func createNew<T>() -> T {
        let className = String(describing: T.self).split(separator:".").first ?? ""
        let newT = NSEntityDescription.insertNewObject(forEntityName: String(className),
                                                       into: CoreDataManager.shared.context) as! T
        return newT
    }

    public static func createNew<T>(typeString: String) -> T {
        let newT = NSEntityDescription.insertNewObject(forEntityName: typeString,
                                                       into: CoreDataManager.shared.context) as! T
        return newT
    }

    public static func fetch<T>(id: String) -> T? {
        return self.fetch(type: T.self, id: id)
    }

    public static func fetch<T>(type: T.Type, id: String) -> T? {
        let className = String(describing: T.self).split(separator: ".").first ?? ""
        let request = NSFetchRequest<Entity>(entityName: String(className))
        request.predicate = NSPredicate(format: "id == %@", id)
        let context = CoreDataManager.shared.context
        let fetchedObjects = try! context?.fetch(request)
        if let first = fetchedObjects?.first {
            return first as? T
        }
        return nil
    }

    public static func fetchOrCreate(typeString: String, with ID: String) -> Entity {
        if let object: Entity = self.fetch(id: ID) {
            return object
        } else {
            let newT = NSEntityDescription.insertNewObject(forEntityName: typeString,
                                                           into: CoreDataManager.shared.context) as! Entity
            newT.id = ID
            return newT
        }
    }

    public static func fetchOrCreate(typeString: String, with dict: [String: Any]) -> Entity? {
        if let id = dict["id"] as? String {
            let object = self.fetchOrCreate(typeString: typeString, with: id)
            object.parse(dict: dict)
            return object
        }
        return nil
    }

    public static func fetchOrCreateObjects(from data: Any?) -> [Entity] {
        guard let dict = data as? [String: Any], let objectsDict = dict["objects"] as? [String: Any] else { return [] }
        var objects: [Entity] = []
        for (_, value) in objectsDict {
            guard let objectDict = value as? [String: Any],
                let type = objectDict["type"] as? String else { continue }
            if let object = self.fetchOrCreate(typeString: type.capitalized, with: objectDict) {
                objects.append(object)
            }
        }
        return objects
    }

}
