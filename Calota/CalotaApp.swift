//
//  CalotaApp.swift
//  Calota
//
//  Created by Deniz Orhan on 02.01.24.
//

import SwiftUI

@main
struct CalotaApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
