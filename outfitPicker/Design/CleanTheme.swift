//
//  CleanTheme.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  Clean, Minimal Design System
//

import SwiftUI

// MARK: - Clean Design Constants

enum CleanDesign {
    // Spacing - Based on 4pt grid
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 24
    static let spacingXXL: CGFloat = 32
    static let spacingXXXL: CGFloat = 48
    
    // Corner Radius
    static let cornerRadiusS: CGFloat = 8
    static let cornerRadiusM: CGFloat = 12
    static let cornerRadiusL: CGFloat = 16
    static let cornerRadiusXL: CGFloat = 20
    static let cornerRadiusFull: CGFloat = 100
    
    // Tab Bar
    static let tabBarHeight: CGFloat = 64
    static let tabBarIconSize: CGFloat = 24
    static let tabBarLabelSize: CGFloat = 10
}

// MARK: - Colors (Severance Aesthetic)

extension Color {
    // Background - Stark White with subtle warmth
    static let cleanBackground = Color(red: 0.99, green: 0.99, blue: 0.98)
    static let cleanCardBg = Color.white
    
    // Text - High contrast, corporate
    static let cleanTextPrimary = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let cleanTextSecondary = Color(red: 0.38, green: 0.38, blue: 0.38)
    static let cleanTextTertiary = Color(red: 0.58, green: 0.58, blue: 0.58)
    
    // Brand - Lumon Orange (Corporate, bold)
    static let cleanOrange = Color(red: 0.95, green: 0.45, blue: 0.15)
    static let cleanOrangeLight = Color(red: 0.99, green: 0.94, blue: 0.90)
    static let cleanOrangeDark = Color(red: 0.80, green: 0.35, blue: 0.10)
    
    // UI - Clean, minimal
    static let cleanBorder = Color(red: 0.92, green: 0.92, blue: 0.92)
    static let cleanShadow = Color.black.opacity(0.06)
    
    // Severance accent - Subtle teal for secondary actions
    static let cleanAccent = Color(red: 0.35, green: 0.55, blue: 0.60)
}

// MARK: - Clean Background

struct CleanBackground: View {
    var body: some View {
        Color.cleanBackground
            .ignoresSafeArea()
    }
}

// MARK: - Soft Card Style

struct SoftCard: ViewModifier {
    var cornerRadius: CGFloat = CleanDesign.cornerRadiusL
    var padding: CGFloat = CleanDesign.spacingL
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.cleanCardBg)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .cleanShadow, radius: 10, x: 0, y: 4)
    }
}

// MARK: - Clean Button Style

struct CleanButtonStyle: ButtonStyle {
    var isProminent: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(isProminent ? .white : .cleanOrange)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: isProminent ? .infinity : nil)
            .background(
                Group {
                    if isProminent {
                        RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusFull)
                            .fill(Color.cleanOrange)
                    } else {
                        RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusFull)
                            .stroke(Color.cleanOrange, lineWidth: 1.5)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Clean Chip/Tag Style

struct CleanChip: View {
    let title: String
    var isSelected: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .cleanTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.cleanTextPrimary : Color.cleanCardBg)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.cleanBorder, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Clean Search Bar

struct CleanSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."
    
    var body: some View {
        HStack(spacing: CleanDesign.spacingM) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.cleanTextTertiary)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
        }
        .padding(.horizontal, CleanDesign.spacingL)
        .padding(.vertical, 14)
        .background(Color.cleanCardBg)
        .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusL))
        .overlay(
            RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusL)
                .stroke(Color.cleanBorder, lineWidth: 1)
        )
    }
}

// MARK: - Clean Prompt Input (Severance Style)

struct CleanPromptInput: View {
    @Binding var text: String
    var placeholder: String = "I need an outfit for..."
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: CleanDesign.spacingM) {
                Image(systemName: "text.bubble")
                    .foregroundColor(isFocused ? .cleanOrange : .cleanTextTertiary)
                    .font(.system(size: 16, weight: .medium))
                
                TextField(placeholder, text: $text, axis: .vertical)
                    .font(.system(size: 15))
                    .lineLimit(1...2)
                    .foregroundColor(.cleanTextPrimary)
                    .focused($isFocused)
            }
            .padding(.bottom, 12)
            
            // Underline
            Rectangle()
                .fill(isFocused ? Color.cleanOrange : Color.cleanBorder)
                .frame(height: isFocused ? 2 : 1)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
        .padding(.horizontal, CleanDesign.spacingS)
    }
}

// MARK: - Pinterest Result Model

struct PinterestResult: Identifiable {
    let id = UUID()
    let imageURL: String
    let title: String
    let source: String
    let pinURL: String
}

// MARK: - View Extensions

extension View {
    func softCard(cornerRadius: CGFloat = CleanDesign.cornerRadiusL, padding: CGFloat = CleanDesign.spacingL) -> some View {
        modifier(SoftCard(cornerRadius: cornerRadius, padding: padding))
    }
    
    func cleanButtonStyle(isProminent: Bool = true) -> some View {
        buttonStyle(CleanButtonStyle(isProminent: isProminent))
    }
}
