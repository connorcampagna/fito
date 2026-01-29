//
//  CleanAddItemSheet.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  Clean Add Item Sheet with AI-powered suggestions
//

import SwiftUI
import SwiftData
import PhotosUI

struct CleanAddItemSheet: View {
    @ObservedObject var viewModel: ClosetViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var clothingItems: [ClothingItem]
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showingUpgradePrompt = false
    
    // Step tracking for multi-step flow
    enum AddItemStep: Int, CaseIterable {
        case photo = 0
        case category = 1
        case aiConfirmation = 2
        case details = 3
    }
    
    @State private var currentStep: AddItemStep = .photo
    @State private var selectedImage: UIImage?
    @State private var selectedCategory: ClothingCategory = .top
    @State private var itemColor: String = ""
    @State private var brand: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var isSaving = false
    @State private var isAnalyzingImage = false
    @State private var suggestedTags: [String] = []
    @State private var aiDescription: String?
    @State private var showingAIConfirmation = false
    
    // Color options
    private let colorOptions = [
        ("Black", Color.black),
        ("White", Color.white),
        ("Navy", Color(red: 0.0, green: 0.0, blue: 0.5)),
        ("Gray", Color.gray),
        ("Beige", Color(red: 0.96, green: 0.96, blue: 0.86)),
        ("Brown", Color.brown),
        ("Red", Color.red),
        ("Blue", Color.blue),
        ("Green", Color.green),
        ("Pink", Color.pink),
        ("Orange", Color.orange),
        ("Yellow", Color.yellow)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                CleanBackground()
                
                ScrollView {
                    VStack(spacing: CleanDesign.spacingXL) {
                        // Photo Section
                        photoSection
                        
                        // Item Type
                        itemTypeSection
                        
                        // AI-Suggested Tags
                        aiTagsSection
                        
                        // Color and Brand Row
                        colorBrandSection
                        
                        Spacer(minLength: CleanDesign.spacingXL)
                        
                        // Bottom Buttons
                        bottomButtons
                    }
                    .padding(CleanDesign.spacingL)
                    .padding(.bottom, CleanDesign.spacingXL)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ADD NEW ITEM")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(.cleanTextPrimary)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.cleanTextSecondary)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                selectedImage = image
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera) { image in
                selectedImage = image
            }
        }
        .onChange(of: selectedCategory) { _, newCategory in
            // Update AI suggested tags when category changes
            if selectedImage != nil {
                updateSuggestedTags(for: newCategory)
            }
        }
        .onChange(of: selectedImage) { _, newImage in
            // Analyze image when selected
            if newImage != nil {
                updateSuggestedTags(for: selectedCategory)
            }
        }
        .sheet(isPresented: $showingUpgradePrompt) {
            SubscriptionPlansView()
        }
    }
    
    private func updateSuggestedTags(for category: ClothingCategory) {
        isAnalyzingImage = true
        suggestedTags = []
        selectedTags = []
        aiDescription = nil
        
        Task {
            let analysis = await AIService.shared.analyzeClothingItem(image: selectedImage, category: category)
            await MainActor.run {
                withAnimation(.spring(response: 0.3)) {
                    isAnalyzingImage = false
                    suggestedTags = analysis.tags
                    aiDescription = analysis.description
                    // Auto-select first 3 AI tags
                    selectedTags = Set(Array(analysis.tags.prefix(3)))
                }
                HapticFeedback.success()
            }
        }
    }
    
    // MARK: - Photo Section
    
    private var photoSection: some View {
        Button(action: {
            showingImagePicker = true
        }) {
            ZStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusL))
                } else {
                    RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusL)
                        .fill(Color.cleanCardBg)
                        .frame(height: 220)
                        .overlay(
                            RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusL)
                                .strokeBorder(
                                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                                )
                                .foregroundColor(.cleanBorder)
                        )
                        .overlay {
                            VStack(spacing: CleanDesign.spacingM) {
                                ZStack {
                                    Circle()
                                        .fill(Color.cleanOrangeLight)
                                        .frame(width: 56, height: 56)
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.cleanOrange)
                                }
                                
                                Text("Tap to upload photo")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.cleanTextSecondary)
                            }
                        }
                }
            }
        }
        .contextMenu {
            Button(action: { showingCamera = true }) {
                Label("Take Photo", systemImage: "camera")
            }
            Button(action: { showingImagePicker = true }) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
            }
        }
    }
    
    // MARK: - Item Type Section
    
    private var itemTypeSection: some View {
        VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
            Text("ITEM TYPE")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundColor(.cleanTextSecondary)
            
            Menu {
                ForEach(ClothingCategory.allCases, id: \.self) { category in
                    Button(action: { 
                        selectedCategory = category
                        HapticFeedback.selection()
                    }) {
                        HStack {
                            Image(systemName: category.icon)
                            Text(category.rawValue)
                            if selectedCategory == category {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selectedCategory.icon)
                        .font(.system(size: 16))
                        .foregroundColor(.cleanOrange)
                    
                    Text(selectedCategory.rawValue.uppercased())
                        .font(.system(size: 14, weight: .medium))
                        .tracking(0.5)
                        .foregroundColor(.cleanTextPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.cleanTextTertiary)
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.cleanBorder, lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - AI Tags Section
    
    private var aiTagsSection: some View {
        VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.cleanOrange, lineWidth: 1)
                        .frame(width: 20, height: 20)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundColor(.cleanOrange)
                }
                
                Text("AI-SUGGESTED TAGS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(.cleanTextSecondary)
                
                if isAnalyzingImage {
                    Spacer()
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Analyzing...")
                            .font(.system(size: 11))
                            .foregroundColor(.cleanTextTertiary)
                    }
                }
            }
            
            if selectedImage == nil {
                // Show placeholder when no image
                Text("Upload a photo to get AI-suggested tags")
                    .font(.system(size: 13))
                    .foregroundColor(.cleanTextTertiary)
                    .padding(.vertical, CleanDesign.spacingM)
            } else if isAnalyzingImage {
                // Loading skeleton
                HStack(spacing: CleanDesign.spacingS) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM)
                            .fill(Color.cleanCardBg)
                            .frame(width: 70, height: 34)
                            .shimmering()
                    }
                }
            } else {
                // AI Description
                if let description = aiDescription {
                    HStack(alignment: .top, spacing: CleanDesign.spacingS) {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 10))
                            .foregroundColor(.cleanOrange)
                        
                        Text(description)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.cleanTextPrimary)
                            .italic()
                    }
                    .padding(CleanDesign.spacingM)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cleanOrangeLight.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM))
                    .padding(.bottom, CleanDesign.spacingS)
                }
                
                FlowLayout(spacing: CleanDesign.spacingS) {
                    ForEach(allAvailableTags, id: \.self) { tag in
                        TagChip(
                            title: tag,
                            isSelected: selectedTags.contains(tag)
                        ) {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                            HapticFeedback.selection()
                        }
                    }
                }
            }
        }
    }
    
    private var allAvailableTags: [String] {
        var tags = suggestedTags
        // Add common tags
        let commonTags = ["Casual", "Formal", "Work", "Date Night", "Weekend", "Summer", "Winter", "Spring", "Fall"]
        for tag in commonTags {
            if !tags.contains(tag) {
                tags.append(tag)
            }
        }
        return Array(tags.prefix(12)) // Limit to 12 tags
    }
    
    // MARK: - Color and Brand Section
    
    private var colorBrandSection: some View {
        HStack(spacing: CleanDesign.spacingM) {
            // Color Field
            VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
                Text("Color")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.cleanTextPrimary)
                
                Menu {
                    ForEach(colorOptions, id: \.0) { colorName, color in
                        Button(action: { itemColor = colorName }) {
                            HStack {
                                Circle()
                                    .fill(color)
                                    .frame(width: 16, height: 16)
                                Text(colorName)
                                if itemColor == colorName {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        if !itemColor.isEmpty {
                            Circle()
                                .fill(colorForName(itemColor))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.cleanBorder, lineWidth: 1)
                                )
                        }
                        
                        Text(itemColor.isEmpty ? "Select" : itemColor)
                            .font(.system(size: 16))
                            .foregroundColor(itemColor.isEmpty ? .cleanTextTertiary : .cleanTextPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.cleanTextTertiary)
                    }
                    .padding(CleanDesign.spacingL)
                    .background(Color.cleanCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM))
                    .shadow(color: .cleanShadow, radius: 4, x: 0, y: 2)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Brand Field
            VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
                Text("Brand")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.cleanTextPrimary)
                
                TextField("Optional", text: $brand)
                    .font(.system(size: 16))
                    .padding(CleanDesign.spacingL)
                    .background(Color.cleanCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM))
                    .shadow(color: .cleanShadow, radius: 4, x: 0, y: 2)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Bottom Buttons
    
    private var bottomButtons: some View {
        VStack(spacing: CleanDesign.spacingM) {
            // Add to Closet Button
            Button(action: {
                saveItem()
            }) {
                HStack(spacing: CleanDesign.spacingS) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(isSaving ? "ADDING..." : "ADD TO CLOSET")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(1)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    selectedImage != nil ? Color.cleanOrange : Color.cleanTextTertiary
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedImage == nil || isSaving || isAnalyzingImage)
            
            // Cancel Button
            Button(action: { dismiss() }) {
                Text("CANCEL")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(0.5)
                    .foregroundColor(.cleanTextSecondary)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func colorForName(_ name: String) -> Color {
        switch name.lowercased() {
        case "black": return .black
        case "white": return .white
        case "navy": return Color(red: 0.0, green: 0.0, blue: 0.5)
        case "gray": return .gray
        case "beige": return Color(red: 0.96, green: 0.96, blue: 0.86)
        case "brown": return .brown
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "pink": return .pink
        case "orange": return .orange
        case "yellow": return .yellow
        default: return .gray
        }
    }
    
    private func saveItem() {
        guard let image = selectedImage else { return }
        
        // Check closet limit for free users
        let closetLimit = 20
        if !subscriptionService.hasActiveSubscription && clothingItems.count >= closetLimit {
            showingUpgradePrompt = true
            HapticFeedback.error()
            return
        }
        
        isSaving = true
        HapticFeedback.selection()
        
        // Build tags from selected tags, color and brand
        var tags = Array(selectedTags)
        if !itemColor.isEmpty && !tags.contains(itemColor) {
            tags.append(itemColor)
        }
        if !brand.isEmpty && !tags.contains(brand) {
            tags.append(brand)
        }
        
        // Save image
        let imagePath = ImageManager.shared.saveImage(image)
        
        // Create clothing item
        let newItem = ClothingItem(
            imagePath: imagePath ?? "",
            category: selectedCategory,
            tags: tags
        )
        
        modelContext.insert(newItem)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            HapticFeedback.success()
            dismiss()
        }
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .cleanTextPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM)
                        .fill(isSelected ? Color.cleanOrange : Color.cleanCardBg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM)
                        .stroke(Color.cleanBorder, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AI Tag Confirmation Sheet

struct AITagConfirmationSheet: View {
    let image: UIImage?
    let category: ClothingCategory
    let aiDescription: String?
    let suggestedTags: [String]
    @Binding var selectedTags: Set<String>
    @Binding var itemColor: String
    @Binding var brand: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var customTag: String = ""
    
    private let colorOptions = [
        ("Black", Color.black),
        ("White", Color.white),
        ("Navy", Color(red: 0.0, green: 0.0, blue: 0.5)),
        ("Gray", Color.gray),
        ("Beige", Color(red: 0.96, green: 0.96, blue: 0.86)),
        ("Brown", Color.brown),
        ("Red", Color.red),
        ("Blue", Color.blue),
        ("Green", Color.green),
        ("Pink", Color.pink),
        ("Orange", Color.orange),
        ("Yellow", Color.yellow)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                CleanBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Item Preview
                        itemPreview
                        
                        // AI Analysis Card
                        aiAnalysisCard
                        
                        // Tag Selection
                        tagSelectionSection
                        
                        // Add Custom Tag
                        customTagSection
                        
                        // Color Selection
                        colorSection
                        
                        // Brand Input
                        brandSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Confirm Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                        onCancel()
                    }
                    .foregroundColor(.cleanTextSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Item") {
                        dismiss()
                        HapticFeedback.success()
                        onConfirm()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.cleanOrange)
                }
            }
        }
    }
    
    // MARK: - Item Preview
    
    private var itemPreview: some View {
        HStack(spacing: 16) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: category.icon)
                        .font(.system(size: 14))
                        .foregroundColor(.cleanOrange)
                    Text(category.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.cleanTextPrimary)
                }
                
                Text("Review the AI-suggested tags below")
                    .font(.system(size: 13))
                    .foregroundColor(.cleanTextSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.cleanCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - AI Analysis Card
    
    private var aiAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.cleanOrange)
                
                Text("AI Analysis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.cleanTextPrimary)
                
                Spacer()
                
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 14))
                
                Text("Complete")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
            }
            
            if let description = aiDescription {
                Text("\"\(description)\"")
                    .font(.system(size: 15))
                    .foregroundColor(.cleanTextSecondary)
                    .italic()
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.cleanOrange.opacity(0.08), Color.cleanOrange.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cleanOrange.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Tag Selection
    
    private var tagSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Tags")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.cleanTextPrimary)
                
                Spacer()
                
                Text("\(selectedTags.count) selected")
                    .font(.system(size: 13))
                    .foregroundColor(.cleanTextTertiary)
            }
            
            Text("Tap to select or deselect tags")
                .font(.system(size: 13))
                .foregroundColor(.cleanTextSecondary)
            
            FlowLayout(spacing: 8) {
                ForEach(allTags, id: \.self) { tag in
                    let isSelected = selectedTags.contains(tag)
                    let isAISuggested = suggestedTags.contains(tag)
                    
                    Button {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                        HapticFeedback.light()
                    } label: {
                        HStack(spacing: 4) {
                            if isAISuggested && isSelected {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10))
                            }
                            Text(tag)
                                .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        }
                        .foregroundColor(isSelected ? .white : .cleanTextSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            isSelected 
                                ? (isAISuggested ? Color.cleanOrange : Color.cleanTextPrimary)
                                : Color.cleanBackground
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.clear : Color.cleanBorder, lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cleanCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var allTags: [String] {
        var tags = suggestedTags
        let commonTags = ["Casual", "Formal", "Work", "Date Night", "Weekend", "Summer", "Winter", "Spring", "Fall", "Cozy", "Trendy", "Classic"]
        for tag in commonTags {
            if !tags.contains(tag) {
                tags.append(tag)
            }
        }
        return tags
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
                    let tag = customTag.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !tag.isEmpty else { return }
                    selectedTags.insert(tag)
                    customTag = ""
                    HapticFeedback.light()
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
    
    // MARK: - Color Section
    
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Primary Color")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.cleanTextPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(colorOptions, id: \.0) { colorName, color in
                    Button {
                        itemColor = colorName
                        HapticFeedback.light()
                    } label: {
                        Circle()
                            .fill(color)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(itemColor == colorName ? Color.cleanOrange : Color.cleanBorder, lineWidth: itemColor == colorName ? 3 : 1)
                            )
                            .overlay(
                                itemColor == colorName 
                                    ? Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(colorName == "White" || colorName == "Beige" ? .black : .white)
                                    : nil
                            )
                    }
                }
            }
        }
        .padding(16)
        .background(Color.cleanCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Brand Section
    
    private var brandSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Brand")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.cleanTextPrimary)
                
                Text("(Optional)")
                    .font(.system(size: 13))
                    .foregroundColor(.cleanTextTertiary)
            }
            
            TextField("e.g. Nike, Zara, H&M", text: $brand)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.cleanBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .background(Color.cleanCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    let container = try! ModelContainer(for: ClothingItem.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    return CleanAddItemSheet(viewModel: ClosetViewModel())
        .modelContainer(container)
}
