//
//  OutfitDetailView.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  Severance-Style Outfit Detail View
//

import SwiftUI
import SwiftData

struct OutfitDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var clothingItems: [ClothingItem]
    
    @Bindable var outfit: Outfit
    @State private var isEditing: Bool = false
    @State private var showingSwapSheet: Bool = false
    @State private var swappingCategory: ClothingCategory?
    @State private var showDeleteConfirmation: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.cleanBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Outfit Items Grid
                        outfitItemsSection
                        
                        // AI Reasoning Section
                        if let reasoning = outfit.aiReasoning {
                            aiReasoningSection(reasoning)
                        }
                        
                        // Style Tip Section
                        if let tip = outfit.styleTip {
                            styleTipSection(tip)
                        }
                        
                        // Outfit Info
                        outfitInfoSection
                        
                        // Actions
                        actionsSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("OUTFIT DETAILS")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(.cleanTextPrimary)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.cleanTextSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Favorite button
                        Button {
                            outfit.isFavorite.toggle()
                            HapticFeedback.light()
                        } label: {
                            Image(systemName: outfit.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(outfit.isFavorite ? .cleanOrange : .cleanTextSecondary)
                        }
                        
                        // Edit button
                        Button {
                            isEditing.toggle()
                            HapticFeedback.light()
                        } label: {
                            Image(systemName: isEditing ? "checkmark" : "pencil")
                                .foregroundColor(.cleanOrange)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSwapSheet) {
                if let category = swappingCategory {
                    ItemSwapSheet(
                        outfit: outfit,
                        category: category,
                        availableItems: clothingItems.filter { $0.category == category }
                    )
                }
            }
            .alert("Delete Outfit?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteOutfit()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Outfit Items Grid (Severance Style)
    
    private var outfitItemsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // Top
                outfitItemCell(
                    item: outfit.top,
                    category: .top,
                    label: "TOP"
                )
                
                // Bottom
                outfitItemCell(
                    item: outfit.bottom,
                    category: .bottom,
                    label: "BOTTOM"
                )
            }
            
            HStack(spacing: 12) {
                // Shoes
                outfitItemCell(
                    item: outfit.shoes,
                    category: .shoes,
                    label: "SHOES"
                )
                
                // Outerwear
                outfitItemCell(
                    item: outfit.outerwear,
                    category: .outerwear,
                    label: "LAYER"
                )
            }
        }
    }
    
    private func outfitItemCell(item: ClothingItem?, category: ClothingCategory, label: String) -> some View {
        VStack(spacing: 8) {
            ZStack {
                if let item = item, let image = ImageManager.shared.loadImage(from: item.imagePath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .frame(width: 140, height: 140)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cleanBorder, lineWidth: 1)
                        )
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.cleanTextTertiary)
                                Text("No \(label)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.cleanTextTertiary)
                            }
                        )
                }
                
                // Edit overlay
                if isEditing && item != nil {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 140, height: 140)
                        .overlay(
                            Button {
                                swappingCategory = category
                                showingSwapSheet = true
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 20))
                                    Text("SWAP")
                                        .font(.system(size: 10, weight: .semibold))
                                        .tracking(0.5)
                                }
                                .foregroundColor(.white)
                            }
                        )
                }
            }
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .tracking(0.5)
                .foregroundColor(.cleanTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - AI Reasoning (Severance Style)
    
    private func aiReasoningSection(_ reasoning: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.cleanOrange, lineWidth: 1)
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(.cleanOrange)
                }
                
                Text("AI STYLING NOTES")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(.cleanTextPrimary)
            }
            
            Text(reasoning)
                .font(.system(size: 14))
                .foregroundColor(.cleanTextSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cleanBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Style Tip (Severance Style)
    
    private func styleTipSection(_ tip: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.cleanTextTertiary, lineWidth: 1)
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.cleanTextTertiary)
                }
                
                Text("STYLE TIP")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(.cleanTextPrimary)
            }
            
            Text(tip)
                .font(.system(size: 14))
                .foregroundColor(.cleanTextSecondary)
                .italic()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cleanBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Outfit Info (Severance Style)
    
    private var outfitInfoSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("CREATED")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.5)
                    .foregroundColor(.cleanTextSecondary)
                Spacer()
                Text(outfit.formattedDate)
                    .font(.system(size: 13))
                    .foregroundColor(.cleanTextPrimary)
            }
            .padding(.vertical, 14)
            
            Divider()
            
            if let prompt = outfit.promptUsed {
                HStack(alignment: .top) {
                    Text("OCCASION")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(0.5)
                        .foregroundColor(.cleanTextSecondary)
                    Spacer()
                    Text(prompt)
                        .font(.system(size: 13))
                        .foregroundColor(.cleanTextPrimary)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.vertical, 14)
                
                Divider()
            }
            
            if let score = outfit.matchScore {
                HStack {
                    Text("MATCH SCORE")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(0.5)
                        .foregroundColor(.cleanTextSecondary)
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(index < score ? Color.cleanOrange : Color.cleanBorder)
                                .frame(width: 16, height: 6)
                        }
                    }
                }
                .padding(.vertical, 14)
            }
        }
        .padding(.horizontal, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cleanBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Actions (Severance Style)
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Share button
            Button {
                shareOutfit()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("SHARE OUTFIT")
                        .tracking(0.5)
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.cleanOrange)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.cleanOrange, lineWidth: 1.5)
                )
            }
            
            // Delete button
            Button {
                showDeleteConfirmation = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                    Text("DELETE OUTFIT")
                        .tracking(0.5)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
        }
    }
    
    // MARK: - Actions
    
    private func shareOutfit() {
        HapticFeedback.light()
    }
    
    private func deleteOutfit() {
        modelContext.delete(outfit)
        HapticFeedback.medium()
        dismiss()
    }
}

// MARK: - Item Swap Sheet (Severance Style)

struct ItemSwapSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var outfit: Outfit
    let category: ClothingCategory
    let availableItems: [ClothingItem]
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.cleanBackground
                    .ignoresSafeArea()
                
                if availableItems.isEmpty {
                    VStack(spacing: 20) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cleanBorder, lineWidth: 1)
                                .frame(width: 72, height: 72)
                            
                            Image(systemName: category.icon)
                                .font(.system(size: 28))
                                .foregroundColor(.cleanTextTertiary)
                        }
                        
                        Text("NO \(category.displayName.uppercased()) AVAILABLE")
                            .font(.system(size: 14, weight: .semibold))
                            .tracking(1)
                            .foregroundColor(.cleanTextPrimary)
                        
                        Text("Add more items to your closet")
                            .font(.system(size: 13))
                            .foregroundColor(.cleanTextSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(availableItems) { item in
                                itemCard(item)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SWAP \(category.displayName.uppercased())")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(.cleanTextPrimary)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.cleanTextSecondary)
                }
            }
        }
    }
    
    private func itemCard(_ item: ClothingItem) -> some View {
        let isSelected = outfit.items.contains { $0.id == item.id }
        
        return Button {
            swapItem(with: item)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    if let image = ImageManager.shared.loadImage(from: item.imagePath) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .frame(width: 100, height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.cleanBorder, lineWidth: 1)
                            )
                    }
                    
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.cleanOrange, lineWidth: 2)
                            .frame(width: 100, height: 100)
                        
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Color.cleanOrange)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            Spacer()
                        }
                        .frame(width: 100, height: 100)
                        .padding(4)
                    }
                }
                
                if !item.tags.isEmpty {
                    Text(item.tags.first?.uppercased() ?? "")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(0.5)
                        .foregroundColor(.cleanTextSecondary)
                        .lineLimit(1)
                }
            }
        }
    }
    
    private func swapItem(with newItem: ClothingItem) {
        outfit.items.removeAll { $0.category == category }
        outfit.items.append(newItem)
        HapticFeedback.medium()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Outfit.self, ClothingItem.self, configurations: config)
    
    let outfit = Outfit(
        promptUsed: "Casual dinner date",
        isFavorite: true,
        aiReasoning: "This combination creates a relaxed yet put-together look perfect for a casual dinner. The neutral tones complement each other well.",
        styleTip: "Add a statement watch or bracelet to elevate the outfit",
        occasion: "Dinner Date",
        matchScore: 4
    )
    
    return OutfitDetailView(outfit: outfit)
        .modelContainer(container)
}
