//
//  YourDrugsApp.swift
//  YourDrugs
//
//  Created by Patryk Opiela on 21/04/2025.
//

import SwiftUI

@main
struct YourDrugsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
