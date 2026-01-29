//
//  AIService.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  AI-Powered Clothing Analysis and Outfit Generation
//

import Foundation
import UIKit

// MARK: - AI Service

actor AIService {
    static let shared = AIService()
    
    private init() {}
    
    // MARK: - Backend-Proxied Outfit Generation
    
    func generateOutfit(
        prompt: String,
        availableItems: [ClothingItemDTO],
        userStyle: String?
    ) async throws -> OutfitSuggestion {
        // Get authenticated user
        guard let user = await AuthService.shared.currentUser else {
            throw AIError.notAuthenticated
        }
        
        guard let token = await AuthService.shared.authToken else {
            throw AIError.notAuthenticated
        }
        
        // Check subscription/usage limits
        let canProceed = await SubscriptionService.shared.canGenerateOutfit
        guard canProceed else {
            throw AIError.usageLimitReached
        }
        
        // Call backend (which holds your OpenAI API key securely)
        let suggestion = try await FitoBackendService.shared.generateOutfit(
            userId: user.id,
            authToken: token,
            prompt: prompt,
            clothingItems: availableItems
        )
        
        // Track usage
        await SubscriptionService.shared.trackOutfitGeneration()
        
        return suggestion
    }
    
    // MARK: - Smart Clothing Analysis (Real AI via GPT-4 Vision)
    
    /// Analyzes clothing item properties and suggests appropriate tags using GPT-4 Vision
    func analyzeClothingItem(image: UIImage?, category: ClothingCategory) async -> ClothingAnalysis {
        // If we have an image, try real AI analysis via backend
        if let image = image {
            // Check if we have auth token
            if let token = await AuthService.shared.authToken {
                do {
                    // Compress and convert to base64
                    guard let imageData = image.jpegData(compressionQuality: 0.4) else {
                        return getLocalAnalysis(for: category)
                    }
                    let base64String = imageData.base64EncodedString()
                    
                    // Call backend with GPT-4 Vision
                    let result = try await FitoBackendService.shared.analyzeImage(
                        imageBase64: base64String,
                        category: category.rawValue,
                        authToken: token
                    )
                    
                    print("✅ AI Image Analysis Success: \(result.tags)")
                    
                    return ClothingAnalysis(
                        category: result.category,
                        tags: result.tags,
                        description: result.description
                    )
                } catch {
                    print("⚠️ AI Image analysis failed: \(error.localizedDescription), using local fallback")
                }
            }
        }
        
        // Fallback to local analysis
        return getLocalAnalysis(for: category)
    }
    
    /// Local fallback analysis when AI is unavailable
    private func getLocalAnalysis(for category: ClothingCategory) -> ClothingAnalysis {
        let suggestedTags = generateSmartTags(for: category)
        let description = generateDescription(for: category)
        
        return ClothingAnalysis(
            category: category.rawValue,
            tags: suggestedTags,
            description: description
        )
    }
    
    /// Generates smart tag suggestions based on clothing category
    private func generateSmartTags(for category: ClothingCategory) -> [String] {
        var baseTags: [String] = []
        
        switch category {
        case .top:
            baseTags = ["Casual", "Cotton", "All-Season"]
        case .bottom:
            baseTags = ["Casual", "Denim", "All-Season"]
        case .shoes:
            baseTags = ["Casual", "Comfortable", "All-Season"]
        case .outerwear:
            baseTags = ["Layering", "Winter", "Warm"]
        case .accessory:
            baseTags = ["Accent", "Versatile", "Statement"]
        }
        
        return baseTags
    }
    
    /// Generates a helpful description based on clothing category
    private func generateDescription(for category: ClothingCategory) -> String {
        switch category {
        case .top:
            return "A versatile top that pairs well with various bottoms"
        case .bottom:
            return "A classic piece that works for multiple occasions"
        case .shoes:
            return "Comfortable footwear suitable for everyday wear"
        case .outerwear:
            return "A layering piece perfect for cooler weather"
        case .accessory:
            return "An accent piece to complete your look"
        }
    }
    
    // MARK: - AI-Powered Outfit Suggestions (For guests/offline)
    
    /// Generates outfit suggestions using local logic when backend is unavailable
    func generateLocalOutfitSuggestion(
        occasion: String,
        items: [ClothingItem],
        weather: String? = nil
    ) -> LocalOutfitSuggestion {
        // Find items by category
        let tops = items.filter { $0.category == .top }
        let bottoms = items.filter { $0.category == .bottom }
        let shoes = items.filter { $0.category == .shoes }
        let outerwear = items.filter { $0.category == .outerwear }
        
        // Smart selection based on occasion and weather
        let selectedTop = selectBestItem(from: tops, for: occasion, weather: weather)
        let selectedBottom = selectBestItem(from: bottoms, for: occasion, weather: weather)
        let selectedShoes = selectBestItem(from: shoes, for: occasion, weather: weather)
        let selectedOuterwear = shouldIncludeOuterwear(weather: weather) 
            ? selectBestItem(from: outerwear, for: occasion, weather: weather) 
            : nil
        
        // Generate style tip
        let styleTip = generateStyleTip(for: occasion)
        
        return LocalOutfitSuggestion(
            top: selectedTop,
            bottom: selectedBottom,
            shoes: selectedShoes,
            outerwear: selectedOuterwear,
            reasoning: "Selected based on \(occasion) occasion",
            styleTip: styleTip
        )
    }
    
    private func selectBestItem(from items: [ClothingItem], for occasion: String, weather: String?) -> ClothingItem? {
        guard !items.isEmpty else { return nil }
        
        // Prioritize items with matching tags
        let occasionKeywords = getOccasionKeywords(occasion)
        
        // Find items with matching tags
        let scoredItems = items.map { item -> (ClothingItem, Int) in
            let score = item.tags.reduce(0) { total, tag in
                occasionKeywords.contains(where: { tag.lowercased().contains($0) }) ? total + 1 : total
            }
            return (item, score)
        }
        
        // Return highest scoring item, or random if no matches
        if let bestMatch = scoredItems.max(by: { $0.1 < $1.1 }), bestMatch.1 > 0 {
            return bestMatch.0
        }
        
        return items.randomElement()
    }
    
    private func getOccasionKeywords(_ occasion: String) -> [String] {
        let lowercased = occasion.lowercased()
        
        if lowercased.contains("work") || lowercased.contains("office") || lowercased.contains("meeting") {
            return ["formal", "business", "professional", "work"]
        } else if lowercased.contains("date") || lowercased.contains("dinner") {
            return ["date", "elegant", "chic", "romantic"]
        } else if lowercased.contains("gym") || lowercased.contains("workout") || lowercased.contains("exercise") {
            return ["active", "athletic", "sporty", "gym"]
        } else if lowercased.contains("casual") || lowercased.contains("everyday") {
            return ["casual", "comfortable", "relaxed", "everyday"]
        } else if lowercased.contains("party") || lowercased.contains("night out") {
            return ["party", "night", "fun", "statement"]
        } else {
            return ["versatile", "casual", "comfortable"]
        }
    }
    
    private func shouldIncludeOuterwear(weather: String?) -> Bool {
        guard let weather = weather?.lowercased() else { return false }
        return weather.contains("cold") || weather.contains("rain") || weather.contains("cool") || weather.contains("winter")
    }
    
    private func generateStyleTip(for occasion: String) -> String {
        let tips = [
            "Confidence is your best accessory!",
            "When in doubt, keep it simple and classic.",
            "Don't forget to accessorize with a watch or simple jewelry.",
            "Make sure your shoes are clean and match the vibe.",
            "Layer thoughtfully for versatility throughout the day.",
            "Trust your instincts - you know what makes you feel great!"
        ]
        return tips.randomElement() ?? tips[0]
    }
    
    // MARK: - Style Advice
    
    func getStyleAdvice(for occasion: String, preferences: String?) async throws -> String {
        guard await AuthService.shared.currentUser != nil else {
            throw AIError.notAuthenticated
        }
        
        // Generate helpful style advice
        let advice = generateLocalStyleAdvice(for: occasion, preferences: preferences)
        return advice
    }
    
    private func generateLocalStyleAdvice(for occasion: String, preferences: String?) -> String {
        let lowercased = occasion.lowercased()
        
        if lowercased.contains("work") || lowercased.contains("office") {
            return "For the office, aim for polished and professional. Neutral colors work well, and make sure everything fits properly. A blazer can elevate any outfit!"
        } else if lowercased.contains("date") {
            return "For a date, wear something that makes you feel confident. Choose an outfit that shows your personality - first impressions matter!"
        } else if lowercased.contains("casual") {
            return "For casual occasions, comfort is key. A well-fitted pair of jeans and a nice top or tee is always a winning combination."
        } else if lowercased.contains("party") || lowercased.contains("night") {
            return "For a night out, don't be afraid to make a statement! Add some color or an interesting accessory to stand out."
        } else {
            return "Focus on comfort and confidence. Trust your instincts and accessorize to express your personal style!"
        }
    }
}

// MARK: - DTOs

struct ClothingItemDTO: Codable {
    let id: String
    let category: String
    let tags: [String]
}

struct OutfitSuggestion: Codable {
    let topId: String?
    let bottomId: String?
    let shoesId: String?
    let outerwearId: String?
    let reasoning: String
    let styleTip: String
    let matchScore: Int?
    
    var selectedItemIds: [String] {
        [topId, bottomId, shoesId, outerwearId].compactMap { $0 }
    }
    
    enum CodingKeys: String, CodingKey {
        case topId = "top_id"
        case bottomId = "bottom_id"
        case shoesId = "shoes_id"
        case outerwearId = "outerwear_id"
        case reasoning
        case styleTip = "style_tip"
        case matchScore
    }
    
    init(topId: String?, bottomId: String?, shoesId: String?, outerwearId: String?, reasoning: String, styleTip: String, matchScore: Int? = nil) {
        self.topId = topId
        self.bottomId = bottomId
        self.shoesId = shoesId
        self.outerwearId = outerwearId
        self.reasoning = reasoning
        self.styleTip = styleTip
        self.matchScore = matchScore
    }
}

struct LocalOutfitSuggestion {
    let top: ClothingItem?
    let bottom: ClothingItem?
    let shoes: ClothingItem?
    let outerwear: ClothingItem?
    let reasoning: String
    let styleTip: String
    
    var hasItems: Bool {
        top != nil || bottom != nil || shoes != nil
    }
}

struct ClothingAnalysis: Codable {
    let category: String
    let tags: [String]
    let description: String?
}

struct ImageAnalysisResult: Codable {
    let category: String
    let color: String
    let tags: [String]
    let description: String?
    let brandGuess: String?
    
    enum CodingKeys: String, CodingKey {
        case category
        case color
        case tags
        case description
        case brandGuess = "brand_guess"
    }
}

// MARK: - Errors

enum AIError: LocalizedError {
    case notAuthenticated
    case usageLimitReached
    case networkError
    case serverError(Int)
    case rateLimited
    case invalidResponse
    case parseError
    case invalidAPIKey
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to use AI features"
        case .usageLimitReached:
            return "You've reached your outfit limit. Upgrade for more!"
        case .networkError:
            return "Network error. Please check your connection."
        case .serverError(let code):
            return "Server error (\(code)). Please try again."
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        case .invalidResponse:
            return "Couldn't understand AI response."
        case .parseError:
            return "Error processing AI response."
        case .invalidAPIKey:
            return "API authentication failed."
        }
    }
}
