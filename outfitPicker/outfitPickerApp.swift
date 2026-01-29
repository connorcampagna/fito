//
//  outfitPickerApp.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//

import SwiftUI
import SwiftData

@main
struct FitoApp: App {
    
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                ClothingItem.self,
                Outfit.self,
                UserProfile.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light) // Force light mode - no dark mode
        }
        .modelContainer(modelContainer)
    }
}
