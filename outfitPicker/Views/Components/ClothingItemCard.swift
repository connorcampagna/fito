//
//  ClothingItemCard.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//

import SwiftUI

struct ClothingItemCard: View {
    let item: ClothingItem
    var showCategory: Bool = true
    var onDelete: (() -> Void)? = nil
    
    @State private var image: UIImage?
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
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
            .frame(minHeight: 120)
            .clipped()
            
            // Info
            if showCategory {
                VStack(alignment: .leading, spacing: CleanDesign.spacingXS) {
                    Text(item.category.displayName)
                        .font(.system(size: 12))
                        .foregroundColor(.cleanTextSecondary)
                    
                    if !item.tags.isEmpty {
                        Text(item.tags.prefix(2).joined(separator: ", "))
                            .font(.system(size: 11))
                            .foregroundColor(.cleanTextTertiary)
                            .lineLimit(1)
                    }
                }
                .padding(CleanDesign.spacingS)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
            }
        }
        .softCard()
        .onTapGesture {
            showingDetail = true
        }
        .onAppear {
            loadImage()
        }
        .sheet(isPresented: $showingDetail) {
            ClothingItemDetailView(item: item, onDelete: onDelete)
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

// MARK: - Detail View

struct ClothingItemDetailView: View {
    let item: ClothingItem
    var onDelete: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Image
                    if let uiImage = image {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 350)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cleanBorder, lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .frame(height: 300)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cleanBorder, lineWidth: 1)
                            )
                            .overlay {
                                ProgressView()
                                    .tint(.cleanTextTertiary)
                            }
                    }
                    
                    // Category
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CATEGORY")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1)
                            .foregroundColor(.cleanTextTertiary)
                        
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.cleanBorder, lineWidth: 1)
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: item.category.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(.cleanTextSecondary)
                            }
                            
                            Text(item.category.displayName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.cleanTextPrimary)
                            
                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.cleanBorder, lineWidth: 1)
                    )
                    
                    // Tags
                    if !item.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TAGS")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(1)
                                .foregroundColor(.cleanTextTertiary)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(item.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 12))
                                        .foregroundColor(.cleanTextPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.cleanBorder, lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.cleanBorder, lineWidth: 1)
                        )
                    }
                    
                    // Date Added
                    HStack {
                        Text("ADDED")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1)
                            .foregroundColor(.cleanTextTertiary)
                        Spacer()
                        Text(item.dateAdded.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 13))
                            .foregroundColor(.cleanTextPrimary)
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.cleanBorder, lineWidth: 1)
                    )
                    
                    // Delete Button
                    if onDelete != nil {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "trash")
                                Text("DELETE ITEM")
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
                }
                .padding(20)
            }
            .background(Color.cleanBackground)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ITEM DETAILS")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(.cleanTextPrimary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.cleanTextSecondary)
                }
            }
            .confirmationDialog("Delete this item?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
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

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

#Preview {
    let item = ClothingItem(
        imagePath: "",
        category: .top,
        tags: ["Casual", "Black", "Summer"]
    )
    
    return ClothingItemCard(item: item)
        .frame(width: 180)
        .padding()
        .background(Color.cleanBackground)
}
