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
