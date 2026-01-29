//
//  OutfitHistoryCard.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//

import SwiftUI

struct OutfitHistoryCard: View {
    let outfit: Outfit
    let onFavoriteToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var isExpanded = false
    @State private var topImage: UIImage?
    @State private var bottomImage: UIImage?
    @State private var shoesImage: UIImage?
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Card Content
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: CleanDesign.spacingM) {
                    // Preview Images Stack
                    ZStack {
                        // Layered preview
                        if let top = topImage {
                            Image(uiImage: top)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM))
                        } else {
                            RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM)
                                .fill(Color.cleanOrangeLight)
                                .frame(width: 70, height: 70)
                        }
                    }
                    
                    // Info
                    VStack(alignment: .leading, spacing: CleanDesign.spacingXS) {
                        if let prompt = outfit.promptUsed, !prompt.isEmpty {
                            Text(prompt)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.cleanTextPrimary)
                                .lineLimit(1)
                        } else {
                            Text("Quick Outfit")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.cleanTextPrimary)
                        }
                        
                        Text("\(outfit.items.count) items")
                            .font(.system(size: 12))
                            .foregroundColor(.cleanTextSecondary)
                        
                        Text(outfit.dateCreated.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11))
                            .foregroundColor(.cleanTextTertiary)
                    }
                    
                    Spacer()
                    
                    // Favorite & Expand
                    VStack(spacing: CleanDesign.spacingS) {
                        Button {
                            onFavoriteToggle()
                        } label: {
                            Image(systemName: outfit.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(outfit.isFavorite ? .cleanOrange : .cleanTextTertiary)
                                .font(.title3)
                        }
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.cleanTextTertiary)
                            .font(.caption)
                    }
                }
                .padding()
            }
            .buttonStyle(.plain)
            
            // Expanded Content
            if isExpanded {
                VStack(spacing: CleanDesign.spacingM) {
                    Divider()
                    
                    // Items Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: CleanDesign.spacingS) {
                        ForEach(outfit.items) { item in
                            ExpandedItemView(item: item)
                        }
                    }
                    
                    // Delete Button
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Remove from History")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    }
                    .padding(.top, CleanDesign.spacingS)
                }
                .padding()
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusL))
        .shadow(
            color: Color.black.opacity(0.06),
            radius: 8,
            x: 0,
            y: 4
        )
        .onAppear {
            loadImages()
        }
    }
    
    private func loadImages() {
        DispatchQueue.global(qos: .userInitiated).async {
            let top = outfit.top.flatMap { ImageManager.shared.loadImage(from: $0.imagePath) }
            let bottom = outfit.bottom.flatMap { ImageManager.shared.loadImage(from: $0.imagePath) }
            let shoes = outfit.shoes.flatMap { ImageManager.shared.loadImage(from: $0.imagePath) }
            
            DispatchQueue.main.async {
                self.topImage = top
                self.bottomImage = bottom
                self.shoesImage = shoes
            }
        }
    }
}

// MARK: - Expanded Item View

struct ExpandedItemView: View {
    let item: ClothingItem
    @State private var image: UIImage?
    
    var body: some View {
        VStack(spacing: CleanDesign.spacingXS) {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusS))
            } else {
                RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusS)
                    .fill(Color.cleanOrangeLight)
                    .frame(height: 80)
                    .overlay {
                        ProgressView()
                            .tint(.cleanOrange)
                    }
            }
            
            Text(item.category.displayName)
                .font(.system(size: 11))
                .foregroundColor(.cleanTextSecondary)
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedImage = ImageManager.shared.loadImage(from: item.imagePath)
            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }
    }
}

#Preview {
    let outfit = Outfit(
        items: [],
        promptUsed: "Casual date night",
        isFavorite: true
    )
    
    return OutfitHistoryCard(
        outfit: outfit,
        onFavoriteToggle: {},
        onDelete: {}
    )
    .padding()
    .background(Color.cleanBackground)
}
