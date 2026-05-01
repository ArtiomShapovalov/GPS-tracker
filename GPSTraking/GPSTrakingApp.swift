//
//  GPSTrakingApp.swift
//  GPSTraking
//
//  Created by Artem Shapovalov on 29.04.2026.
//

import SwiftUI
import CoreData

@main
struct GPSTrakingApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
