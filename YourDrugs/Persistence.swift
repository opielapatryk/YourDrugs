//
//  Persistence.swift
//  YourDrugs
//
//  Created by Patryk Opiela on 23/04/2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "HealthModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { (_, error) in
            if let error = error as NSError? {
                fatalError("Loading Core Data failed: \(error), \(error.userInfo)")
            }
        }
    }
}

