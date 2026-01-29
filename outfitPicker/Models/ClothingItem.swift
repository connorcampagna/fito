//
//  ClothingItem.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//

import Foundation
import SwiftData

@Model
final class ClothingItem {
    var id: UUID
    var imagePath: String
    var categoryRaw: String
    var tags: [String]
    var dateAdded: Date
    
    var category: ClothingCategory {
        get { ClothingCategory(rawValue: categoryRaw) ?? .top }
        set { categoryRaw = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        imagePath: String,
        category: ClothingCategory,
        tags: [String] = [],
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.imagePath = imagePath
        self.categoryRaw = category.rawValue
        self.tags = tags
        self.dateAdded = dateAdded
    }
}

// MARK: - Tag Suggestions
extension ClothingItem {
    static let suggestedTags: [String] = [
        // Style
        "Casual", "Formal", "Business", "Active", "Loungewear", "Party",
        // Season
        "Summer", "Winter", "Spring", "Fall", "All-Season",
        // Colors
        "Black", "White", "Navy", "Gray", "Brown", "Beige", "Red", "Blue", "Green", "Pink", "Orange", "Yellow", "Purple",
        // Patterns
        "Solid", "Striped", "Plaid", "Floral", "Graphic",
        // Material
        "Cotton", "Denim", "Leather", "Wool", "Silk", "Linen",
        // Occasion
        "Work", "Date Night", "Gym", "Beach", "Travel", "Wedding"
    ]
}
