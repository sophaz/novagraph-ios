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

    public static func fetch<T: NSManagedObject>(id: String) -> T? {
        let className = String(String(describing: T.self).split(separator: ".").first ?? "")
        return self.fetch(entity: className, id: id) as? T
    }

    public static func fetchOrCreate<T: NSManagedObject & HasID>(id: String) -> T {
        if let object = self.fetch(id: id) as? T {
            return object
        } else {
            let className = String(String(describing: T.self).split(separator: ".").first ?? "")
            var newT = NSEntityDescription.insertNewObject(forEntityName: className,
                                                           into: CoreDataManager.shared.context) as! T
            newT.id = id
            return newT
        }
    }

    public static func fetchOrCreate(dict: [String: Any]) -> NSManagedObject? {
        if let id = dict["id"] as? String, let type = dict["type"] as? String {
            let entityString = type.capitalized
            if let object = CoreDataManager.fetch(entity: entityString, id: id) as? NSManagedObject & Parseable {
                object.parse(data: dict)
                return object
            }
        }
        return nil
    }

    public static func fetchOrCreateObjects(from data: Any?) -> [NSManagedObject] {
        guard let dict = data as? [String: Any], let objectsDict = dict["objects"] as? [String: Any] else { return [] }
        var objects: [NSManagedObject] = []
        for (_, value) in objectsDict {
            guard let objectDict = value as? [String: Any] else { continue }
            if let object = CoreDataManager.fetchOrCreate(dict: objectDict) {
                objects.append(object)
            }
        }
        return objects
    }

    private static func fetch(entity: String, id: String) -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: entity)
        request.predicate = NSPredicate(format: "id == %@", id)
        let context = CoreDataManager.shared.context
        let fetchedObjects = try! context?.fetch(request)
        return fetchedObjects?.first
    }
}
