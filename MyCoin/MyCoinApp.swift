//
//  MyCoinApp.swift
//  MyCoin
//
//  Created by Rassul Bessimbekov on 11.12.2024.
//

import SwiftUI
import SwiftData

@main
struct MyCoinApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for: Token.self, User.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
