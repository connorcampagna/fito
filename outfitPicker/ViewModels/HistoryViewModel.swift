//
//  HistoryViewModel.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//

import Foundation
import SwiftData

@MainActor
final class HistoryViewModel: ObservableObject {
    
    @Published var selectedOutfit: Outfit?
    @Published var showingDetail: Bool = false
    
    func toggleFavorite(_ outfit: Outfit) {
        outfit.isFavorite.toggle()
    }
    
    func deleteOutfit(_ outfit: Outfit, from modelContext: ModelContext) {
        modelContext.delete(outfit)
    }
}
