//
//  HomeViewModel.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  Now with Secure Backend AI Integration!
//

import Foundation
import SwiftData

@MainActor
final class HomeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var prompt: String = ""
    @Published var isGenerating: Bool = false
    @Published var generatedOutfit: GeneratedOutfit?
    @Published var showingResult: Bool = false
    @Published var errorMessage: String?
    @Published var showingSubscriptionPlans: Bool = false
    
    // AI-related properties
    @Published var aiReasoning: String?
    @Published var aiStyleTip: String?
    @Published var loadingRotation: Double = 0
    @Published var loadingMessage: String = "Analyzing your wardrobe..."
    
    // MARK: - AI Status
    
    var isAIEnabled: Bool {
        // AI is now always enabled for authenticated users via backend
        AuthService.shared.isAuthenticated
    }
    
    var isPremiumUser: Bool {
        SubscriptionService.shared.hasActiveSubscription
    }
    
    // MARK: - Generated Outfit Result
    
    struct GeneratedOutfit {
        let top: ClothingItem?
        let bottom: ClothingItem?
        let shoes: ClothingItem?
        let outerwear: ClothingItem?
        let matchedKeywords: [String]
        
        var items: [ClothingItem] {
            [top, bottom, shoes, outerwear].compactMap { $0 }
        }
        
        var isValid: Bool {
            top != nil || bottom != nil || shoes != nil
        }
    }
    
    // MARK: - Loading Messages
    
    private let loadingMessages = [
        "Analyzing your wardrobe...",
        "Considering color harmony...",
        "Checking style compatibility...",
        "Finding the perfect match...",
        "Almost there..."
    ]
    
    // MARK: - Keyword Mappings for Mock AI
    
    private let keywordTagMappings: [String: [String]] = [
        // Activities
        "gym": ["Active", "Gym", "Casual"],
        "workout": ["Active", "Gym"],
        "exercise": ["Active", "Gym"],
        "run": ["Active", "Gym"],
        "sport": ["Active", "Gym"],
        
        // Occasions
        "date": ["Date Night", "Formal", "Party"],
        "dinner": ["Date Night", "Formal", "Party"],
        "interview": ["Formal", "Business", "Work"],
        "meeting": ["Business", "Work", "Formal"],
        "work": ["Work", "Business"],
        "office": ["Work", "Business"],
        "wedding": ["Wedding", "Formal", "Party"],
        "party": ["Party", "Date Night"],
        "club": ["Party", "Date Night"],
        "beach": ["Beach", "Summer", "Casual"],
        "travel": ["Travel", "Casual", "Loungewear"],
        
        // Seasons/Weather
        "winter": ["Winter", "Wool", "Outerwear"],
        "cold": ["Winter", "Wool", "Outerwear"],
        "snow": ["Winter", "Wool"],
        "summer": ["Summer", "Linen", "Cotton"],
        "hot": ["Summer", "Linen"],
        "spring": ["Spring", "All-Season"],
        "fall": ["Fall", "All-Season"],
        "autumn": ["Fall", "All-Season"],
        "rain": ["All-Season", "Outerwear"],
        "rainy": ["All-Season", "Outerwear"],
        
        // Styles
        "casual": ["Casual", "Loungewear"],
        "relaxed": ["Casual", "Loungewear"],
        "chill": ["Casual", "Loungewear"],
        "formal": ["Formal", "Business"],
        "fancy": ["Formal", "Party"],
        "elegant": ["Formal", "Party"],
        
        // Colors
        "black": ["Black"],
        "white": ["White"],
        "blue": ["Blue", "Navy"],
        "red": ["Red"],
        "green": ["Green"],
        "pink": ["Pink"],
    ]
    
    private let outerwearKeywords = ["winter", "cold", "snow", "rain", "rainy", "jacket", "coat", "chilly", "freezing"]
    
    // MARK: - Stylist Logic
    
    func generateOutfit(from items: [ClothingItem]) {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter what you're doing today!"
            return
        }
        
        guard !items.isEmpty else {
            errorMessage = "Your closet is empty! Add some clothes first."
            return
        }
        
        // Check subscription limits before generating
        if let status = SubscriptionService.shared.subscriptionStatus,
           status.requestsRemaining <= 0,
           !SubscriptionService.shared.hasActiveSubscription {
            errorMessage = "You've used all your free generations this month"
            showingSubscriptionPlans = true
            HapticFeedback.error()
            return
        }
        
        isGenerating = true
        errorMessage = nil
        aiReasoning = nil
        aiStyleTip = nil
        loadingRotation = 0
        
        // Start loading message animation
        startLoadingMessageAnimation()
        
        if isAIEnabled {
            // Use real AI
            generateWithAI(from: items)
        } else {
            // Use smart matching fallback
            generateWithSmartMatching(from: items)
        }
    }
    
    private func startLoadingMessageAnimation() {
        Task { @MainActor in
            var messageIndex = 0
            while isGenerating {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                if isGenerating {
                    messageIndex = (messageIndex + 1) % loadingMessages.count
                    loadingMessage = loadingMessages[messageIndex]
                }
            }
        }
    }
    
    private func generateWithAI(from items: [ClothingItem]) {
        Task {
            do {
                // Convert clothing items to DTOs for AI
                let itemDTOs = items.map { item in
                    ClothingItemDTO(
                        id: item.id.uuidString,
                        category: item.category.rawValue,
                        tags: item.tags
                    )
                }
                
                let suggestion = try await AIService.shared.generateOutfit(
                    prompt: prompt,
                    availableItems: itemDTOs,
                    userStyle: nil
                )
                
                // Match AI selections to actual items
                let outfit = matchAISuggestion(suggestion, to: items)
                
                self.aiReasoning = suggestion.reasoning
                self.aiStyleTip = suggestion.styleTip
                self.generatedOutfit = outfit
                self.isGenerating = false
                
                if outfit.isValid {
                    self.showingResult = true
                    HapticFeedback.success()
                } else {
                    self.errorMessage = "Nothing suitable for this occasion! Try adding more clothes to your closet 👗👔"
                }
            } catch AIError.notAuthenticated {
                self.isGenerating = false
                self.errorMessage = "Please sign in to use AI styling"
            } catch AIError.usageLimitReached {
                self.isGenerating = false
                self.errorMessage = "You've reached your monthly limit"
                self.showingSubscriptionPlans = true
            } catch {
                // Fallback to smart matching on AI error
                print("AI Error: \(error)")
                self.aiReasoning = nil
                generateWithSmartMatching(from: items)
            }
        }
    }
    
    private func matchAISuggestion(_ suggestion: OutfitSuggestion, to items: [ClothingItem]) -> GeneratedOutfit {
        // Try to match selected IDs to actual items
        var selectedTop: ClothingItem?
        var selectedBottom: ClothingItem?
        var selectedShoes: ClothingItem?
        var selectedOuterwear: ClothingItem?
        
        for itemId in suggestion.selectedItemIds {
            if let item = items.first(where: { $0.id.uuidString == itemId }) {
                switch item.category {
                case .top:
                    selectedTop = item
                case .bottom:
                    selectedBottom = item
                case .shoes:
                    selectedShoes = item
                case .outerwear:
                    selectedOuterwear = item
                case .accessory:
                    break // Handle accessories separately if needed
                }
            }
        }
        
        return GeneratedOutfit(
            top: selectedTop,
            bottom: selectedBottom,
            shoes: selectedShoes,
            outerwear: selectedOuterwear,
            matchedKeywords: []
        )
    }
    
    private func generateWithSmartMatching(from items: [ClothingItem]) {
        // Simulate processing delay for non-AI matching
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self = self else { return }
            
            let outfit = self.matchOutfit(from: items)
            self.generatedOutfit = outfit
            
            // Generate AI-style comment based on the outfit
            if outfit.isValid {
                self.aiReasoning = self.generateOutfitComment(for: outfit, prompt: self.prompt)
                self.aiStyleTip = self.generateStyleTip(for: self.prompt)
            }
            
            self.isGenerating = false
            
            if outfit.isValid {
                self.showingResult = true
                HapticFeedback.success()
            } else {
                self.errorMessage = "Nothing suitable for this occasion! Try adding more clothes to your closet 👗👔"
            }
        }
    }
    
    /// Generates a personalized comment about the outfit
    private func generateOutfitComment(for outfit: GeneratedOutfit, prompt: String) -> String {
        let promptLower = prompt.lowercased()
        var comments: [String] = []
        
        // Occasion-based comments
        if promptLower.contains("date") || promptLower.contains("dinner") {
            comments = [
                "This look strikes the perfect balance between effort and effortlessness - you'll definitely make an impression! ✨",
                "I've put together something that says 'I care' without trying too hard. Confidence is your best accessory tonight!",
                "This combo is giving sophisticated but approachable vibes - exactly what you want for tonight! 💫"
            ]
        } else if promptLower.contains("work") || promptLower.contains("office") || promptLower.contains("meeting") || promptLower.contains("interview") {
            comments = [
                "Clean, professional, and polished - you'll command the room with this look! 💼",
                "This outfit says 'I mean business' while still showing off your personal style.",
                "Power dressing at its finest - you've got this! Ready to conquer the day. ⭐"
            ]
        } else if promptLower.contains("gym") || promptLower.contains("workout") || promptLower.contains("exercise") {
            comments = [
                "Functional meets fashionable - you'll look great crushing those goals! 💪",
                "Comfort and style for your workout - no excuses not to hit it hard today!",
                "Athletic chic! You'll feel as good as you look during your session. 🏋️"
            ]
        } else if promptLower.contains("party") || promptLower.contains("night out") || promptLower.contains("club") {
            comments = [
                "You're going to turn heads with this look! Get ready to own the night! 🌟",
                "Statement-making and memorable - this outfit is pure main character energy!",
                "Party-ready and fabulous! The dancefloor won't know what hit it. 🎉"
            ]
        } else if promptLower.contains("casual") || promptLower.contains("chill") || promptLower.contains("relaxed") {
            comments = [
                "Effortlessly cool and comfortable - the perfect laid-back look! 😎",
                "Casual doesn't mean boring - this combo keeps it stylish while keeping you comfy.",
                "Easy, breezy, and totally you - perfect for wherever the day takes you!"
            ]
        } else if promptLower.contains("cold") || promptLower.contains("winter") || promptLower.contains("rain") {
            comments = [
                "Cozy meets chic! You'll stay warm without sacrificing style. ❄️",
                "Layered to perfection - this look will keep you toasty and looking great!",
                "Weather-ready and fashionable - bring on the elements! 🧥"
            ]
        } else if promptLower.contains("summer") || promptLower.contains("hot") || promptLower.contains("beach") {
            comments = [
                "Light, fresh, and perfect for soaking up the sun! ☀️",
                "Summer vibes all the way - cool, comfortable, and camera-ready!",
                "This breezy look will keep you cool while looking hot! 🌴"
            ]
        } else {
            comments = [
                "A versatile combination that works for wherever your day takes you! ✨",
                "I've picked pieces that complement each other beautifully - you're all set!",
                "This thoughtfully curated look balances style and practicality perfectly. 👌",
                "A winning combination! You'll feel confident and put-together all day.",
                "These pieces work so well together - sometimes the classics just hit different! 💫"
            ]
        }
        
        return comments.randomElement() ?? comments[0]
    }
    
    /// Generates a style tip based on the occasion
    private func generateStyleTip(for prompt: String) -> String {
        let promptLower = prompt.lowercased()
        
        if promptLower.contains("interview") || promptLower.contains("meeting") {
            return "Pro tip: Arrive 10 minutes early so you can settle in with confidence! 💼"
        } else if promptLower.contains("date") {
            return "Remember: a genuine smile is the best accessory you can wear! 💕"
        } else if promptLower.contains("gym") {
            return "Don't forget to stretch before and after - you've got this! 💪"
        } else if promptLower.contains("cold") || promptLower.contains("winter") {
            return "Layer smart: you can always take off a layer if you warm up! 🧣"
        } else if promptLower.contains("party") {
            return "Wear what makes YOU feel amazing - confidence is contagious! 🎉"
        } else {
            let tips = [
                "Confidence is your best accessory - wear it proudly! ✨",
                "When in doubt, accessories can elevate any look! 💫",
                "The right outfit can change your whole mood - own it! 🌟",
                "Style tip: make sure your shoes are clean - it's the details that count! 👟"
            ]
            return tips.randomElement() ?? tips[0]
        }
    }
    
    private func matchOutfit(from items: [ClothingItem]) -> GeneratedOutfit {
        let promptLower = prompt.lowercased()
        var matchedKeywords: [String] = []
        var relevantTags: Set<String> = []
        
        // Parse prompt for keywords
        for (keyword, tags) in keywordTagMappings {
            if promptLower.contains(keyword) {
                matchedKeywords.append(keyword)
                relevantTags.formUnion(tags)
            }
        }
        
        // Check if outerwear should be included
        let needsOuterwear = outerwearKeywords.contains { promptLower.contains($0) }
        
        // Categorize items
        let tops = items.filter { $0.category == .top }
        let bottoms = items.filter { $0.category == .bottom }
        let shoes = items.filter { $0.category == .shoes }
        let outerwear = items.filter { $0.category == .outerwear }
        
        // Select items (prioritize matching tags, fallback to random)
        let selectedTop = selectBestMatch(from: tops, matchingTags: relevantTags)
        let selectedBottom = selectBestMatch(from: bottoms, matchingTags: relevantTags)
        let selectedShoes = selectBestMatch(from: shoes, matchingTags: relevantTags)
        let selectedOuterwear = needsOuterwear ? selectBestMatch(from: outerwear, matchingTags: relevantTags) : nil
        
        return GeneratedOutfit(
            top: selectedTop,
            bottom: selectedBottom,
            shoes: selectedShoes,
            outerwear: selectedOuterwear,
            matchedKeywords: matchedKeywords
        )
    }
    
    private func selectBestMatch(from items: [ClothingItem], matchingTags: Set<String>) -> ClothingItem? {
        guard !items.isEmpty else { return nil }
        
        // If we have matching tags, try to find items that match
        if !matchingTags.isEmpty {
            // Score each item by how many matching tags it has
            let scored = items.map { item -> (ClothingItem, Int) in
                let itemTags = Set(item.tags)
                let matchCount = itemTags.intersection(matchingTags).count
                return (item, matchCount)
            }
            
            // Get items with the highest score
            let maxScore = scored.max(by: { $0.1 < $1.1 })?.1 ?? 0
            
            if maxScore > 0 {
                let bestMatches = scored.filter { $0.1 == maxScore }.map { $0.0 }
                return bestMatches.randomElement()
            }
        }
        
        // Fallback: return random item
        return items.randomElement()
    }
    
    func regenerate(from items: [ClothingItem]) {
        generateOutfit(from: items)
    }
    
    func saveOutfit(to modelContext: ModelContext) -> Outfit? {
        guard let generated = generatedOutfit, generated.isValid else { return nil }
        
        let outfit = Outfit(
            items: generated.items,
            promptUsed: prompt,
            isFavorite: false,
            aiReasoning: aiReasoning,
            styleTip: aiStyleTip,
            occasion: prompt
        )
        
        modelContext.insert(outfit)
        return outfit
    }
    
    func reset() {
        prompt = ""
        generatedOutfit = nil
        showingResult = false
        errorMessage = nil
    }
    
    // MARK: - Prompt Suggestions
    
    static let promptSuggestions = [
        "Job interview today",
        "Casual coffee date",
        "Gym workout session",
        "Dinner party tonight",
        "Rainy day walk",
        "Beach day with friends",
        "Working from home",
        "Wedding guest outfit",
        "Winter shopping trip",
        "Summer festival"
    ]
}
