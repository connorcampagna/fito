//
//  CleanClosetView.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  Clean, Minimal Closet Design
//

import SwiftUI
import SwiftData

struct CleanClosetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClothingItem.dateAdded, order: .reverse) private var clothingItems: [ClothingItem]
    
    @StateObject private var viewModel = ClosetViewModel()
    @State private var selectedCategory: ClothingCategory? = nil
    @State private var showingAddSheet = false
    @State private var selectedItem: ClothingItem?
    
    private var filteredItems: [ClothingItem] {
        guard let category = selectedCategory else { return clothingItems }
        return clothingItems.filter { $0.category == category }
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: CleanDesign.spacingM),
        GridItem(.flexible(), spacing: CleanDesign.spacingM),
        GridItem(.flexible(), spacing: CleanDesign.spacingM)
    ]
    
    var body: some View {
        ZStack {
            CleanBackground()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Category Filter
                categoryFilter
                
                // Items Grid
                ScrollView {
                    if filteredItems.isEmpty {
                        emptyState
                    } else {
                        itemsGrid
                    }
                }
            }
            
            // Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    addButton
                        .padding(.trailing, CleanDesign.spacingL)
                        .padding(.bottom, 90) // Account for tab bar
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            CleanAddItemSheet(viewModel: viewModel)
        }
        .sheet(item: $selectedItem) { item in
            ClothingItemDetailSheet(item: item)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MY CLOSET")
                    .font(.system(size: 24, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.cleanTextPrimary)
                
                Text("\(clothingItems.count) items")
                    .font(.system(size: 13))
                    .foregroundColor(.cleanTextSecondary)
            }
            
            Spacer()
            
            // Search button
            Button(action: {}) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.cleanBorder, lineWidth: 1)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(.cleanTextSecondary)
                }
            }
        }
        .padding(.horizontal, CleanDesign.spacingL)
        .padding(.top, CleanDesign.spacingL)
        .padding(.bottom, CleanDesign.spacingM)
    }
    
    // MARK: - Category Filter
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: CleanDesign.spacingS) {
                // All button
                CategoryChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    count: clothingItems.count
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = nil
                    }
                    HapticFeedback.selection()
                }
                
                // Category buttons
                ForEach(ClothingCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        count: clothingItems.filter { $0.category == category }.count
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                        HapticFeedback.selection()
                    }
                }
            }
            .padding(.horizontal, CleanDesign.spacingL)
        }
        .padding(.bottom, CleanDesign.spacingL)
    }
    
    // MARK: - Items Grid
    
    private var itemsGrid: some View {
        LazyVGrid(columns: columns, spacing: CleanDesign.spacingM) {
            ForEach(filteredItems) { item in
                ClosetItemCard(item: item) {
                    selectedItem = item
                }
            }
        }
        .padding(.horizontal, CleanDesign.spacingL)
        .padding(.bottom, 100)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: CleanDesign.spacingL) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.cleanBorder, lineWidth: 1)
                    .frame(width: 72, height: 72)
                
                Image(systemName: "hanger")
                    .font(.system(size: 28))
                    .foregroundColor(.cleanTextTertiary)
            }
            
            Text("NO ITEMS YET")
                .font(.system(size: 16, weight: .semibold))
                .tracking(1)
                .foregroundColor(.cleanTextPrimary)
            
            Text("Tap the + button to add your first clothing item")
                .font(.system(size: 14))
                .foregroundColor(.cleanTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(CleanDesign.spacingXXL)
    }
    
    // MARK: - Add Button
    
    private var addButton: some View {
        Button(action: { 
            showingAddSheet = true
            HapticFeedback.medium()
        }) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.cleanOrange)
                .clipShape(Circle())
                .shadow(color: .cleanOrange.opacity(0.35), radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    var isSelected: Bool = false
    var count: Int? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 6) {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .tracking(0.5)
                
                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.cleanOrange.opacity(0.15))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : .cleanTextPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.cleanTextPrimary : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.cleanBorder, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Closet Item Card

struct ClosetItemCard: View {
    let item: ClothingItem
    var onTap: (() -> Void)? = nil
    
    @State private var image: UIImage?
    
    var body: some View {
        Button(action: { onTap?() }) {
            ZStack {
                RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM)
                    .fill(Color.cleanBackground)
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM))
                } else {
                    Image(systemName: item.category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.cleanTextTertiary)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .shadow(color: .cleanShadow, radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .onAppear { loadImage() }
    }
    
    private func loadImage() {
        let path = item.imagePath
        guard !path.isEmpty else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedImage = ImageManager.shared.loadImage(from: path)
            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }
    }
}

// MARK: - Clothing Item Detail Sheet

struct ClothingItemDetailSheet: View {
    let item: ClothingItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var image: UIImage?
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                CleanBackground()
                
                ScrollView {
                    VStack(spacing: CleanDesign.spacingL) {
                        // Image
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 280)
                                .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusL))
                        } else {
                            RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusL)
                                .fill(Color.cleanCardBg)
                                .frame(height: 280)
                                .overlay(
                                    Image(systemName: item.category.icon)
                                        .font(.system(size: 56))
                                        .foregroundColor(.cleanTextTertiary)
                                )
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
                            Text("Category")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.cleanTextSecondary)
                            
                            Text(item.category.rawValue)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.cleanTextPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(CleanDesign.spacingL)
                        .background(Color.cleanCardBg)
                        .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM))
                        .shadow(color: .cleanShadow, radius: 6, x: 0, y: 2)
                        
                        // Tags
                        VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
                            Text("Tags")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.cleanTextSecondary)
                            
                            FlowLayout(spacing: CleanDesign.spacingS) {
                                ForEach(item.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 13))
                                        .foregroundColor(.cleanTextPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.cleanBackground)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(CleanDesign.spacingL)
                        .background(Color.cleanCardBg)
                        .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM))
                        .shadow(color: .cleanShadow, radius: 6, x: 0, y: 2)
                        
                        // Delete Button
                        Button(action: { showDeleteAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Item")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(CleanDesign.spacingL)
                            .background(Color.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM))
                        }
                    }
                    .padding(CleanDesign.spacingL)
                }
            }
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.cleanOrange)
                }
            }
        }
        .onAppear { loadImage() }
        .alert("Delete Item?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(item)
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private func loadImage() {
        let path = item.imagePath
        guard !path.isEmpty else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedImage = ImageManager.shared.loadImage(from: path)
            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }
    }
}

#Preview {
    CleanClosetView()
        .modelContainer(for: [ClothingItem.self, Outfit.self, UserProfile.self], inMemory: true)
}
