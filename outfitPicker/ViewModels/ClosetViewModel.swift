//
//  ClosetViewModel.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//

import Foundation
import SwiftUI
import SwiftData
import PhotosUI

@MainActor
final class ClosetViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var selectedCategory: ClothingCategory? = nil
    @Published var showingAddSheet = false
    @Published var showingImagePicker = false
    @Published var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    // Add Item Flow
    @Published var selectedImage: UIImage?
    @Published var selectedPhotosPickerItem: PhotosPickerItem?
    @Published var newItemCategory: ClothingCategory = .top
    @Published var newItemTags: Set<String> = []
    @Published var customTag: String = ""
    @Published var isProcessingImage = false
    
    // MARK: - Computed Properties
    
    var filteredItems: (FetchDescriptor<ClothingItem>) {
        var descriptor = FetchDescriptor<ClothingItem>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        
        if let category = selectedCategory {
            descriptor.predicate = #Predicate<ClothingItem> { item in
                item.categoryRaw == category.rawValue
            }
        }
        
        return descriptor
    }
    
    // MARK: - Methods
    
    func processSelectedPhoto() async {
        guard let item = selectedPhotosPickerItem else { return }
        
        isProcessingImage = true
        defer { isProcessingImage = false }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                selectedImage = uiImage
                showingAddSheet = true
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }
    
    func saveNewItem(to modelContext: ModelContext) -> Bool {
        guard let image = selectedImage else { return false }
        
        // Save image to disk
        guard let imagePath = ImageManager.shared.saveImage(image) else {
            print("Failed to save image")
            return false
        }
        
        // Create new clothing item
        let newItem = ClothingItem(
            imagePath: imagePath,
            category: newItemCategory,
            tags: Array(newItemTags)
        )
        
        modelContext.insert(newItem)
        
        // Reset state
        resetAddItemState()
        
        return true
    }
    
    func resetAddItemState() {
        selectedImage = nil
        selectedPhotosPickerItem = nil
        newItemCategory = .top
        newItemTags = []
        customTag = ""
        showingAddSheet = false
    }
    
    func toggleTag(_ tag: String) {
        if newItemTags.contains(tag) {
            newItemTags.remove(tag)
        } else {
            newItemTags.insert(tag)
        }
    }
    
    func addCustomTag() {
        let trimmed = customTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            newItemTags.insert(trimmed)
            customTag = ""
        }
    }
    
    func deleteItem(_ item: ClothingItem, from modelContext: ModelContext) {
        // Delete image from disk
        ImageManager.shared.deleteImage(at: item.imagePath)
        
        // Delete from SwiftData
        modelContext.delete(item)
    }
}
