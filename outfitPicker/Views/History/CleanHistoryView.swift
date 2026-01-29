//
//  CleanHistoryView.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  Clean History View matching design mockups
//

import SwiftUI
import SwiftData

struct CleanHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Outfit.dateCreated, order: .reverse) private var allOutfits: [Outfit]
    
    @State private var selectedFilter: OutfitFilter = .all
    @State private var selectedOutfit: Outfit?
    
    enum OutfitFilter: String, CaseIterable {
        case all = "All"
        case casual = "Casual"
        case work = "Work"
        case dateNight = "Date Night"
    }
    
    private var filteredOutfits: [Outfit] {
        guard selectedFilter != .all else { return allOutfits }
        return allOutfits.filter { outfit in
            guard let prompt = outfit.promptUsed?.lowercased() else { return false }
            switch selectedFilter {
            case .casual: return prompt.contains("casual") || prompt.contains("coffee") || prompt.contains("brunch")
            case .work: return prompt.contains("work") || prompt.contains("office") || prompt.contains("meeting")
            case .dateNight: return prompt.contains("date") || prompt.contains("dinner") || prompt.contains("night")
            case .all: return true
            }
        }
    }
    
    private var thisWeekOutfits: [Outfit] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return filteredOutfits.filter { $0.dateCreated >= weekAgo }
    }
    
    private var lastMonthOutfits: [Outfit] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return filteredOutfits.filter { $0.dateCreated < weekAgo && $0.dateCreated >= monthAgo }
    }
    
    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: CleanDesign.spacingM),
         GridItem(.flexible(), spacing: CleanDesign.spacingM)]
    }
    
    var body: some View {
        ZStack {
            CleanBackground()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Filter Chips
                filterSection
                
                // Content
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: CleanDesign.spacingXL) {
                        if allOutfits.isEmpty {
                            emptyState
                        } else if filteredOutfits.isEmpty {
                            noResultsState
                        } else {
                            // This Week Section
                            if !thisWeekOutfits.isEmpty {
                                outfitSection(
                                    title: "This Week",
                                    badge: "\(thisWeekOutfits.count) New",
                                    outfits: thisWeekOutfits
                                )
                            }
                            
                            // Last Month Section
                            if !lastMonthOutfits.isEmpty {
                                outfitSection(
                                    title: "Last Month",
                                    outfits: lastMonthOutfits
                                )
                            }
                        }
                    }
                    .padding(.horizontal, CleanDesign.spacingL)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(item: $selectedOutfit) { outfit in
            OutfitDetailSheet(
                outfit: outfit,
                onDelete: {
                    selectedOutfit = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        deleteOutfit(outfit)
                    }
                },
                onFavoriteToggle: {
                    outfit.isFavorite.toggle()
                }
            )
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Text("SAVED LOOKS")
                .font(.system(size: 24, weight: .bold))
                .tracking(2)
                .foregroundColor(.cleanTextPrimary)
            
            Spacer()
            
            Button(action: {}) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.cleanBorder, lineWidth: 1)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 16))
                        .foregroundColor(.cleanTextPrimary)
                }
            }
        }
        .padding(.horizontal, CleanDesign.spacingL)
        .padding(.top, CleanDesign.spacingL)
        .padding(.bottom, CleanDesign.spacingM)
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: CleanDesign.spacingS) {
                ForEach(OutfitFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                        HapticFeedback.selection()
                    }
                }
            }
            .padding(.horizontal, CleanDesign.spacingL)
        }
        .padding(.bottom, CleanDesign.spacingL)
    }
    
    // MARK: - Outfit Section
    
    private func outfitSection(title: String, badge: String? = nil, outfits: [Outfit]) -> some View {
        VStack(alignment: .leading, spacing: CleanDesign.spacingM) {
            // Section Header
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.cleanTextPrimary)
                
                Spacer()
                
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.cleanOrange)
                }
            }
            
            // Outfit Grid
            LazyVGrid(columns: columns, spacing: CleanDesign.spacingM) {
                ForEach(outfits) { outfit in
                    HistoryOutfitCard(outfit: outfit) {
                        deleteOutfit(outfit)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedOutfit = outfit
                        HapticFeedback.selection()
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: CleanDesign.spacingL) {
            // Geometric icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.cleanBorder, lineWidth: 1)
                    .frame(width: 72, height: 72)
                
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 28))
                    .foregroundColor(.cleanTextTertiary)
            }
            
            Text("NO OUTFITS YET")
                .font(.system(size: 16, weight: .semibold))
                .tracking(1)
                .foregroundColor(.cleanTextPrimary)
            
            Text("Your saved outfits will appear here.\nGo to Home and let Fito style you!")
                .font(.system(size: 14))
                .foregroundColor(.cleanTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CleanDesign.spacingXXXL)
    }
    
    private var noResultsState: some View {
        VStack(spacing: CleanDesign.spacingL) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.cleanBorder, lineWidth: 1)
                    .frame(width: 64, height: 64)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 24))
                    .foregroundColor(.cleanTextTertiary)
            }
            
            Text("NO \(selectedFilter.rawValue.uppercased()) OUTFITS")
                .font(.system(size: 14, weight: .semibold))
                .tracking(1)
                .foregroundColor(.cleanTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CleanDesign.spacingXXL)
    }
    
    // MARK: - Actions
    
    private func deleteOutfit(_ outfit: Outfit) {
        HapticFeedback.warning()
        withAnimation(.spring(response: 0.3)) {
            modelContext.delete(outfit)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .tracking(0.5)
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

// MARK: - History Outfit Card

struct HistoryOutfitCard: View {
    let outfit: Outfit
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    @State private var mainImage: UIImage?
    
    private var eventName: String {
        guard let prompt = outfit.promptUsed else { return "Custom Outfit" }
        // Extract event name from prompt
        if prompt.lowercased().contains("coffee") { return "Coffee Date" }
        if prompt.lowercased().contains("office") || prompt.lowercased().contains("work") { return "Office Pitch" }
        if prompt.lowercased().contains("gallery") { return "Gallery Opening" }
        if prompt.lowercased().contains("nyc") || prompt.lowercased().contains("trip") { return "NYC Trip" }
        if prompt.lowercased().contains("brunch") { return "Brunch" }
        return String(prompt.prefix(20))
    }
    
    private var eventType: String {
        guard let prompt = outfit.promptUsed?.lowercased() else { return "Casual" }
        if prompt.contains("work") || prompt.contains("office") { return "Work" }
        if prompt.contains("date") || prompt.contains("dinner") { return "Date Night" }
        if prompt.contains("formal") || prompt.contains("gallery") { return "Formal" }
        if prompt.contains("travel") || prompt.contains("trip") { return "Travel" }
        return "Casual"
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(outfit.dateCreated)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
            // Image
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusL)
                    .fill(Color.cleanBackground)
                    .frame(height: 180)
                    .overlay {
                        if let image = mainImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusL))
                        } else {
                            // Outfit preview placeholder
                            VStack(spacing: CleanDesign.spacingS) {
                                Image(systemName: "tshirt")
                                    .font(.system(size: 32))
                                    .foregroundColor(.cleanTextTertiary)
                            }
                        }
                    }
                    .clipped()
                
                // Today badge
                if isToday {
                    Text("TODAY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.cleanTextPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.cleanCardBg)
                        .clipShape(Capsule())
                        .shadow(color: .cleanShadow, radius: 4, x: 0, y: 2)
                        .padding(CleanDesign.spacingS)
                }
            }
            
            // Event Name
            Text(eventName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.cleanTextPrimary)
                .lineLimit(1)
            
            // Date & Type
            HStack(spacing: 4) {
                Text(outfit.dateCreated.formatted(.dateTime.month(.abbreviated).day()))
                Text("•")
                Text(eventType)
            }
            .font(.system(size: 12))
            .foregroundColor(.cleanTextSecondary)
        }
        .onAppear { loadImage() }
        .contextMenu {
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete Outfit?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func loadImage() {
        guard let firstItem = outfit.items.first else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let image = ImageManager.shared.loadImage(from: firstItem.imagePath)
            DispatchQueue.main.async {
                self.mainImage = image
            }
        }
    }
}

// MARK: - Create New Outfit Card

struct CreateNewOutfitCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusL)
            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
            .foregroundColor(.cleanBorder)
            .frame(height: 180)
            .overlay {
                VStack(spacing: CleanDesign.spacingS) {
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(.cleanOrange)
                    
                    Text("Create New")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.cleanOrange)
                }
            }
    }
}

// MARK: - Outfit Detail Sheet

struct OutfitDetailSheet: View {
    let outfit: Outfit
    let onDelete: () -> Void
    let onFavoriteToggle: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var itemImages: [UUID: UIImage] = [:]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        if let prompt = outfit.promptUsed, !prompt.isEmpty {
                            Text(prompt.uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .tracking(1)
                                .foregroundColor(.cleanTextPrimary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("QUICK OUTFIT")
                                .font(.system(size: 18, weight: .bold))
                                .tracking(1)
                                .foregroundColor(.cleanTextPrimary)
                        }
                        
                        Text(outfit.dateCreated.formatted(date: .long, time: .shortened))
                            .font(.system(size: 12))
                            .foregroundColor(.cleanTextSecondary)
                    }
                    .padding(.top)
                    
                    // Outfit Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(outfit.items) { item in
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .frame(height: 140)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.cleanBorder, lineWidth: 1)
                                        )
                                    
                                    if let image = itemImages[item.id] {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 140)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        ProgressView()
                                            .tint(.cleanTextTertiary)
                                    }
                                }
                                
                                Text(item.category.displayName.uppercased())
                                    .font(.system(size: 10, weight: .medium))
                                    .tracking(0.5)
                                    .foregroundColor(.cleanTextSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Favorite Button
                        Button {
                            onFavoriteToggle()
                            HapticFeedback.selection()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: outfit.isFavorite ? "heart.fill" : "heart")
                                Text(outfit.isFavorite ? "REMOVE FROM FAVORITES" : "ADD TO FAVORITES")
                                    .tracking(0.5)
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.cleanOrange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.cleanOrange, lineWidth: 1)
                            )
                        }
                        
                        // Delete Button
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash")
                                Text("DELETE OUTFIT")
                                    .tracking(0.5)
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.cleanBorder, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(Color.cleanBackground)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("OUTFIT DETAILS")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(.cleanTextPrimary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 14))
                        .foregroundColor(.cleanTextSecondary)
                }
            }
        }
        .onAppear {
            loadImages()
        }
    }
    
    private func loadImages() {
        for item in outfit.items {
            DispatchQueue.global(qos: .userInitiated).async {
                let image = ImageManager.shared.loadImage(from: item.imagePath)
                DispatchQueue.main.async {
                    if let image = image {
                        itemImages[item.id] = image
                    }
                }
            }
        }
    }
}

#Preview {
    CleanHistoryView()
        .modelContainer(for: [ClothingItem.self, Outfit.self, UserProfile.self], inMemory: true)
}
