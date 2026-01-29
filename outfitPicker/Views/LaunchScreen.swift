//
//  LaunchScreen.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//

import SwiftUI

struct LaunchScreen: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [Color.cleanBackground, Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: CleanDesign.spacingL) {
                // Animated Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.cleanOrange, .cleanOrangeLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .cleanOrange.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }
                
                // App Name
                VStack(spacing: CleanDesign.spacingXS) {
                    Text("Fito")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.cleanTextPrimary)
                    
                    Text("Your AI-Powered Stylist")
                        .font(.system(size: 15))
                        .foregroundColor(.cleanTextSecondary)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    LaunchScreen()
}
