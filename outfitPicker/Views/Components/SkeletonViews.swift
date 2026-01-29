//
//  SkeletonViews.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  Skeleton Loading Views for Better Perceived Performance
//

import SwiftUI

// MARK: - Skeleton Base

struct SkeletonShape: View {
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 8
    var color: Color = Color.gray.opacity(0.2)
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(color)
            .frame(height: height)
            .shimmer()
    }
}

// MARK: - Closet Item Skeleton

struct ClothingItemSkeleton: View {
    var body: some View {
        VStack(spacing: 8) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
                .aspectRatio(1, contentMode: .fit)
                .shimmer()
            
            // Label placeholder
            SkeletonShape(height: 12, cornerRadius: 4)
                .frame(width: 60)
        }
    }
}

struct ClosetGridSkeleton: View {
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(0..<12, id: \.self) { _ in
                ClothingItemSkeleton()
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Home View Skeleton

struct HomeViewSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header skeleton
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonShape(height: 14, cornerRadius: 4)
                        .frame(width: 100)
                    SkeletonShape(height: 28, cornerRadius: 6)
                        .frame(width: 180)
                }
                Spacer()
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .shimmer()
            }
            
            // Daily tip skeleton
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 100)
                .shimmer()
            
            // Occasion chips skeleton
            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 80, height: 36)
                        .shimmer()
                }
            }
            
            // Prompt area skeleton
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 60)
                .shimmer()
            
            // Button skeleton
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.gray.opacity(0.15))
                .frame(height: 56)
                .shimmer()
            
            // Inspiration section skeleton
            VStack(alignment: .leading, spacing: 12) {
                SkeletonShape(height: 18, cornerRadius: 4)
                    .frame(width: 140)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.12))
                                .frame(width: 160, height: 200)
                                .shimmer()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// MARK: - History Skeleton

struct OutfitHistorySkeleton: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<4, id: \.self) { _ in
                HStack(spacing: 16) {
                    // Image placeholder
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .shimmer()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonShape(height: 16, cornerRadius: 4)
                            .frame(width: 140)
                        SkeletonShape(height: 12, cornerRadius: 3)
                            .frame(width: 100)
                        SkeletonShape(height: 12, cornerRadius: 3)
                            .frame(width: 80)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(Color.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Profile Skeleton

struct ProfileSkeleton: View {
    var body: some View {
        VStack(spacing: 24) {
            // Avatar
            Circle()
                .fill(Color.gray.opacity(0.15))
                .frame(width: 100, height: 100)
                .shimmer()
            
            // Name and email
            VStack(spacing: 8) {
                SkeletonShape(height: 24, cornerRadius: 6)
                    .frame(width: 160)
                SkeletonShape(height: 14, cornerRadius: 4)
                    .frame(width: 200)
            }
            
            // Stats
            HStack(spacing: 40) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 8) {
                        SkeletonShape(height: 28, cornerRadius: 6)
                            .frame(width: 50)
                        SkeletonShape(height: 12, cornerRadius: 3)
                            .frame(width: 60)
                    }
                }
            }
            
            // Settings rows
            VStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .shimmer()
                        
                        SkeletonShape(height: 16, cornerRadius: 4)
                            .frame(width: 120)
                        
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    
                    if #available(iOS 17.0, *) {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color.gray.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 20)
        .padding(.top, 40)
    }
}

// MARK: - Subscription Plans Skeleton

struct SubscriptionPlansSkeleton: View {
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                SkeletonShape(height: 28, cornerRadius: 6)
                    .frame(width: 180)
                SkeletonShape(height: 14, cornerRadius: 4)
                    .frame(width: 260)
            }
            .padding(.top, 40)
            
            // Plan cards
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 180)
                    .shimmer()
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Previews

#Preview("Closet Skeleton") {
    ClosetGridSkeleton()
}

#Preview("Home Skeleton") {
    HomeViewSkeleton()
}

#Preview("History Skeleton") {
    OutfitHistorySkeleton()
}
