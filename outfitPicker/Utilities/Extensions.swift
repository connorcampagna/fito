//
//  Extensions.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//

import SwiftUI

// MARK: - View Extensions

extension View {
    /// Applies a shimmer loading effect (always on)
    func shimmer() -> some View {
        self.modifier(ShimmerModifier(isActive: true))
    }
    
    /// Applies a shimmer loading effect
    func shimmer(isActive: Bool) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }
    
    /// Always-on shimmer effect for loading states
    func shimmering() -> some View {
        self.modifier(ShimmerModifier(isActive: true))
    }
    
    /// Hides the view conditionally
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }
    
    /// Dismiss keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay(
                    GeometryReader { geometry in
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                .white.opacity(0.5),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                    }
                )
                .mask(content)
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

// MARK: - Date Extensions

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    var relativeDescription: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else {
            return formatted(date: .abbreviated, time: .omitted)
        }
    }
}

// MARK: - String Extensions

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isNotEmpty: Bool {
        !trimmed.isEmpty
    }
}

// MARK: - Array Extensions

extension Array where Element == ClothingItem {
    func grouped(by category: ClothingCategory) -> [ClothingItem] {
        filter { $0.category == category }
    }
    
    var tops: [ClothingItem] { grouped(by: .top) }
    var bottoms: [ClothingItem] { grouped(by: .bottom) }
    var shoes: [ClothingItem] { grouped(by: .shoes) }
    var outerwear: [ClothingItem] { grouped(by: .outerwear) }
    var accessories: [ClothingItem] { grouped(by: .accessory) }
}

// MARK: - Haptic Feedback

enum HapticFeedback {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
