//
//  EditClothingItemSheet.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  Edit Clothing Item Flow
//

import SwiftUI
import SwiftData
import PhotosUI

struct EditClothingItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var item: ClothingItem
    
    @State private var selectedCategory: ClothingCategory
    @State private var selectedTags: Set<String>
    @State private var customTag: String = ""
    @State private var showingPhotoOptions: Bool = false
    @State private var showingPhotoPicker: Bool = false
    @State private var showingCamera: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var newImage: UIImage?
    @State private var showDeleteConfirmation: Bool = false
    @State private var isSaving: Bool = false
    
    init(item: ClothingItem) {
        self.item = item
        _selectedCategory = State(initialValue: item.category)
        _selectedTags = State(initialValue: Set(item.tags))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                CleanBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Photo Section
                        photoSection
                        
                        // Category Section
                        categorySection
                        
                        // Tags Section
                        tagsSection
                        
                        // Custom Tag Input
                        customTagSection
                        
                        // Suggested Tags
                        suggestedTagsSection
                        
                        // Delete Button
                        deleteButton
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.cleanTextSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.cleanOrange)
                    .disabled(isSaving)
                }
            }
            .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                loadPhoto(from: newItem)
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(sourceType: .camera) { image in
                    newImage = image
                }
            }
            .confirmationDialog("Change Photo", isPresented: $showingPhotoOptions) {
                Button("Take Photo") {
                    showingCamera = true
                }
                Button("Choose from Library") {
                    showingPhotoPicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert("Delete Item?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteItem()
                }
            } message: {
                Text("This item will be removed from your closet and any outfits it's in.")
            }
        }
    }
    
    // MARK: - Photo Section
    
    private var photoSection: some View {
        VStack(spacing: 12) {
            ZStack {
                if let newImage = newImage {
                    Image(uiImage: newImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 180, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else if let existingImage = ImageManager.shared.loadImage(from: item.imagePath) {
                    Image(uiImage: existingImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 180, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cleanCardBg)
                        .frame(width: 180, height: 180)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.cleanTextTertiary)
                        )
                }
                
                // Edit badge
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingPhotoOptions = true
                        } label: {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.cleanOrange)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .frame(width: 180, height: 180)
                .padding(8)
            }
            
            Text("Tap camera to change photo")
                .font(.system(size: 13))
                .foregroundColor(.cleanTextTertiary)
        }
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.cleanTextPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(ClothingCategory.allCases, id: \.self) { category in
                    categoryButton(category)
                }
            }
        }
        .padding(16)
        .background(Color.cleanCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func categoryButton(_ category: ClothingCategory) -> some View {
        let isSelected = selectedCategory == category
        
        return Button {
            selectedCategory = category
            HapticFeedback.light()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 20))
                Text(category.displayName)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .cleanTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.cleanOrange : Color.cleanBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tags")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.cleanTextPrimary)
                
                Spacer()
                
                Text("\(selectedTags.count) selected")
                    .font(.system(size: 13))
                    .foregroundColor(.cleanTextTertiary)
            }
            
            if selectedTags.isEmpty {
                Text("No tags added yet")
                    .font(.system(size: 14))
                    .foregroundColor(.cleanTextTertiary)
                    .padding(.vertical, 8)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(Array(selectedTags).sorted(), id: \.self) { tag in
                        tagChip(tag, isRemovable: true)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cleanCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func tagChip(_ tag: String, isRemovable: Bool) -> some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.system(size: 13, weight: .medium))
            
            if isRemovable {
                Button {
                    selectedTags.remove(tag)
                    HapticFeedback.light()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                }
            }
        }
        .foregroundColor(.cleanOrange)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.cleanOrange.opacity(0.12))
        .clipShape(Capsule())
    }
    
    // MARK: - Custom Tag Section
    
    private var customTagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Custom Tag")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.cleanTextPrimary)
            
            HStack(spacing: 12) {
                TextField("Enter tag name", text: $customTag)
                    .font(.system(size: 15))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.cleanBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Button {
                    addCustomTag()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(customTag.isEmpty ? Color.gray : Color.cleanOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(customTag.isEmpty)
            }
        }
        .padding(16)
        .background(Color.cleanCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Suggested Tags
    
    private var suggestedTagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested Tags")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.cleanTextPrimary)
            
            FlowLayout(spacing: 8) {
                ForEach(ClothingItem.suggestedTags.filter { !selectedTags.contains($0) }.prefix(20), id: \.self) { tag in
                    Button {
                        selectedTags.insert(tag)
                        HapticFeedback.light()
                    } label: {
                        Text(tag)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.cleanTextSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.cleanBackground)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.cleanBorder, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cleanCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Delete Button
    
    private var deleteButton: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Item")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Actions
    
    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    newImage = image
                }
            }
        }
    }
    
    private func addCustomTag() {
        let tag = customTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tag.isEmpty else { return }
        
        selectedTags.insert(tag)
        customTag = ""
        HapticFeedback.light()
    }
    
    private func saveChanges() {
        isSaving = true
        
        // Update category
        item.category = selectedCategory
        
        // Update tags
        item.tags = Array(selectedTags).sorted()
        
        // Update photo if changed
        if let newImage = newImage {
            // Delete old image
            ImageManager.shared.deleteImage(at: item.imagePath)
            
            // Save new image
            if let newPath = ImageManager.shared.saveImage(newImage) {
                item.imagePath = newPath
            }
        }
        
        HapticFeedback.success()
        dismiss()
    }
    
    private func deleteItem() {
        // Delete image file
        ImageManager.shared.deleteImage(at: item.imagePath)
        
        // Delete from database
        modelContext.delete(item)
        
        HapticFeedback.medium()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ClothingItem.self, configurations: config)
    
    let item = ClothingItem(
        imagePath: "test.jpg",
        category: .top,
        tags: ["Casual", "Cotton", "Blue"]
    )
    
    return EditClothingItemSheet(item: item)
        .modelContainer(container)
}
