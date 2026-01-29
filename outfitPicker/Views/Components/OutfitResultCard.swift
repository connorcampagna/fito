//
//  OutfitResultCard.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//

import SwiftUI

struct OutfitResultCard: View {
    let outfit: HomeViewModel.GeneratedOutfit
    let onSave: () -> Void
    let onRegenerate: () -> Void
    
    @State private var isSaved = false
    @State private var showingSaveAnimation = false
    
    var body: some View {
        VStack(spacing: CleanDesign.spacingL) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: CleanDesign.spacingXS) {
                    Text("YOUR OUTFIT")
                        .font(.system(size: 14, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.cleanTextPrimary)
                    
                    if !outfit.matchedKeywords.isEmpty {
                        Text("Matched: \(outfit.matchedKeywords.joined(separator: ", "))")
                            .font(.system(size: 12))
                            .foregroundColor(.cleanOrange)
                    }
                }
                Spacer()
            }
            
            // Outfit Items Grid
            outfitGrid
            
            // Action Buttons
            HStack(spacing: CleanDesign.spacingM) {
                // Save Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isSaved = true
                        showingSaveAnimation = true
                    }
                    onSave()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showingSaveAnimation = false
                    }
                } label: {
                    HStack {
                        Image(systemName: isSaved ? "heart.fill" : "heart")
                            .scaleEffect(showingSaveAnimation ? 1.3 : 1)
                        Text(isSaved ? "Saved!" : "Save")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.cleanOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isSaved)
                
                // Regenerate Button
                Button {
                    isSaved = false
                    onRegenerate()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("New")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.cleanOrange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.cleanCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cleanOrange, lineWidth: 1.5)
                    )
                }
            }
        }
        .padding(CleanDesign.spacingL)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusXL))
        .overlay(
            RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusXL)
                .stroke(Color.cleanBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Outfit Grid
    
    private var outfitGrid: some View {
        VStack(spacing: CleanDesign.spacingM) {
            // Top Row: Top + Outerwear (if present)
            HStack(spacing: CleanDesign.spacingM) {
                if let top = outfit.top {
                    OutfitItemView(item: top, label: "Top")
                }
                
                if let outerwear = outfit.outerwear {
                    OutfitItemView(item: outerwear, label: "Layer")
                }
            }
            
            // Bottom Row: Bottom + Shoes
            HStack(spacing: CleanDesign.spacingM) {
                if let bottom = outfit.bottom {
                    OutfitItemView(item: bottom, label: "Bottom")
                }
                
                if let shoes = outfit.shoes {
                    OutfitItemView(item: shoes, label: "Shoes")
                }
            }
        }
    }
}

// MARK: - Outfit Item View

struct OutfitItemView: View {
    let item: ClothingItem
    let label: String
    
    @State private var image: UIImage?
    
    var body: some View {
        VStack(spacing: CleanDesign.spacingXS) {
            ZStack {
                if let uiImage = image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.cleanOrangeLight)
                        .overlay {
                            ProgressView()
                                .tint(.cleanOrange)
                        }
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM))
            
            Text(label)
                .font(.system(size: 12))
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

// MARK: - Preview

#Preview {
    let sampleOutfit = HomeViewModel.GeneratedOutfit(
        top: ClothingItem(imagePath: "", category: .top, tags: ["Casual"]),
        bottom: ClothingItem(imagePath: "", category: .bottom, tags: ["Casual"]),
        shoes: ClothingItem(imagePath: "", category: .shoes, tags: ["Casual"]),
        outerwear: nil,
        matchedKeywords: ["casual", "date"]
    )
    
    return OutfitResultCard(
        outfit: sampleOutfit,
        onSave: {},
        onRegenerate: {}
    )
    .padding()
    .background(Color.cleanBackground)
}
