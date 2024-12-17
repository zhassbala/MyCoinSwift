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
            let schema = Schema([
                Token.self,
                User.self,
                CodeRepoData.self,
                FacebookData.self,
                RedditData.self,
                TwitterData.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: modelConfiguration)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
