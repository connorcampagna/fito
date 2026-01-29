//
//  EmptyStateView.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: CleanDesign.spacingL) {
            // Animated Icon
            ZStack {
                Circle()
                    .fill(Color.cleanOrange.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                
                Circle()
                    .fill(Color.cleanOrange.opacity(0.15))
                    .frame(width: 110, height: 110)
                
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(.cleanOrange)
            }
            
            // Title
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.cleanTextPrimary)
                .multilineTextAlignment(.center)
            
            // Message
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.cleanTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, CleanDesign.spacingXL)
            
            // Action Button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.cleanOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, CleanDesign.spacingM)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    EmptyStateView(
        icon: "tshirt",
        title: "Your Closet is Empty",
        message: "Start by adding your first piece of clothing. Tap the + button to get started!",
        actionTitle: "Add First Item"
    ) {
        print("Action tapped")
    }
    .padding()
    .background(Color.cleanBackground)
}
