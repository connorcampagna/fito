//
//  UserProfile.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var stylePreferences: String
    var profileImagePath: String?
    var bodyMeasurements: String?
    var favoriteColors: [String]
    var preferredStyles: [String]
    var gender: String?  // "male", "female", "non-binary", etc.
    var ageRange: String?  // "18-24", "25-34", "35-44", "45-54", "55+"
    
    init(
        id: UUID = UUID(),
        name: String = "",
        stylePreferences: String = "",
        profileImagePath: String? = nil,
        bodyMeasurements: String? = nil,
        favoriteColors: [String] = [],
        preferredStyles: [String] = [],
        gender: String? = nil,
        ageRange: String? = nil
    ) {
        self.id = id
        self.name = name
        self.stylePreferences = stylePreferences
        self.profileImagePath = profileImagePath
        self.bodyMeasurements = bodyMeasurements
        self.favoriteColors = favoriteColors
        self.preferredStyles = preferredStyles
        self.gender = gender
        self.ageRange = ageRange
    }
    
    // Helper computed properties
    var stylePreferencesText: String {
        if !preferredStyles.isEmpty {
            return preferredStyles.prefix(2).joined(separator: ", ")
        }
        return stylePreferences.isEmpty ? "Not set" : stylePreferences
    }
    
    var measurementsText: String {
        bodyMeasurements?.isEmpty == false ? bodyMeasurements! : "Not set"
    }
}
