//
//  ProfileViewModel.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//

import Foundation
import SwiftData

@MainActor
final class ProfileViewModel: ObservableObject {
    
    @Published var showingDeleteConfirmation = false
    @Published var showingPrivacyPolicy = false
    @Published var isEditingName = false
    @Published var editedName = ""
    
    func startEditingName(_ currentName: String) {
        editedName = currentName
        isEditingName = true
    }
    
    func saveName(to profile: UserProfile) {
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            profile.name = trimmed
        }
        isEditingName = false
    }
    
    func cancelEditing() {
        isEditingName = false
        editedName = ""
    }
    
    func deleteAllData(modelContext: ModelContext, clothingItems: [ClothingItem], outfits: [Outfit]) {
        // Delete all images from disk
        ImageManager.shared.deleteAllImages()
        
        // Delete all clothing items
        for item in clothingItems {
            modelContext.delete(item)
        }
        
        // Delete all outfits
        for outfit in outfits {
            modelContext.delete(outfit)
        }
    }
}
