//
//  ClothingCategory.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//

import Foundation

enum ClothingCategory: String, Codable, CaseIterable, Identifiable {
    case top = "Top"
    case bottom = "Bottom"
    case shoes = "Shoes"
    case outerwear = "Outerwear"
    case accessory = "Accessory"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .top: return "tshirt"
        case .bottom: return "figure.walk"
        case .shoes: return "shoe"
        case .outerwear: return "cloud.snow"
        case .accessory: return "sparkles"
        }
    }
    
    var displayName: String {
        rawValue
    }
}
