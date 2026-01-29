//
//  Outfit.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//

import Foundation
import SwiftData

@Model
final class Outfit {
    var id: UUID
    @Relationship(deleteRule: .nullify) var items: [ClothingItem]
    var promptUsed: String?
    var isFavorite: Bool
    var dateCreated: Date
    var aiReasoning: String?
    var styleTip: String?
    var occasion: String?
    var matchScore: Int?
    
    init(
        id: UUID = UUID(),
        items: [ClothingItem] = [],
        promptUsed: String? = nil,
        isFavorite: Bool = false,
        dateCreated: Date = Date(),
        aiReasoning: String? = nil,
        styleTip: String? = nil,
        occasion: String? = nil,
        matchScore: Int? = nil
    ) {
        self.id = id
        self.items = items
        self.promptUsed = promptUsed
        self.isFavorite = isFavorite
        self.dateCreated = dateCreated
        self.aiReasoning = aiReasoning
        self.styleTip = styleTip
        self.occasion = occasion
        self.matchScore = matchScore
    }
    
    // Helper computed properties
    var top: ClothingItem? {
        items.first { $0.category == .top }
    }
    
    var bottom: ClothingItem? {
        items.first { $0.category == .bottom }
    }
    
    var shoes: ClothingItem? {
        items.first { $0.category == .shoes }
    }
    
    var outerwear: ClothingItem? {
        items.first { $0.category == .outerwear }
    }
    
    var accessories: [ClothingItem] {
        items.filter { $0.category == .accessory }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dateCreated)
    }
    
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: dateCreated, relativeTo: Date())
    }
}

