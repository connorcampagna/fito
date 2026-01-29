//
//  CleanHomeView.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  Severance-Inspired Home Design
//

import SwiftUI
import SwiftData

struct CleanHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var clothingItems: [ClothingItem]
    @Query private var savedOutfits: [Outfit]
    
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var subscriptionService = SubscriptionService.shared
    @FocusState private var isPromptFocused: Bool
    @State private var dailyTip: String = ""
    @State private var hasBeenSaved: Bool = false
    @State private var suggestedOccasions: [OccasionSuggestion] = []
    @State private var showingUpgradeForSave = false
    
    private var userName: String {
        userProfiles.first?.name ?? "Sarah"
    }
    
    var body: some View {
        ZStack {
            CleanBackground()
            
            ScrollView {
                VStack(alignment: .leading, spacing: CleanDesign.spacingXL) {
                    // Header
                    headerSection
                    
                    // AI Daily Suggestion
                    aiDailySuggestion
                    
                    // Quick Occasion Suggestions
                    occasionSuggestionsSection
                    
                    // Prompt Input
                    promptSection
                    
                    // Style Me Button
                    styleMeButton
                    
                    // Generated Outfit Result - ABOVE inspiration
                    if viewModel.showingResult, let outfit = viewModel.generatedOutfit {
                        generatedLookSection(outfit: outfit)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                    
                    // Error Message
                    if let error = viewModel.errorMessage {
                        errorView(error)
                    }
                    
                    // Empty state
                    if clothingItems.isEmpty {
                        emptyClosetPrompt
                    }
                    
                    // Fito Pro Upsell
                    FitoProUpsellCard()
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, CleanDesign.spacingL)
                .padding(.top, CleanDesign.spacingS)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                hideKeyboard()
            }
            
            // Loading overlay
            if viewModel.isGenerating {
                loadingOverlay
            }
        }
        .sheet(isPresented: $viewModel.showingSubscriptionPlans) {
            SubscriptionPlansView()
        }
        .sheet(isPresented: $showingUpgradeForSave) {
            SubscriptionPlansView()
        }
        .onAppear {
            loadSuggestedOccasions()
        }
    }
    
    // MARK: - Header Section (Severance Style)
    
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("HELLO, \(userName.uppercased())")
                    .font(.system(size: 22, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.cleanTextPrimary)
                
                Text("What are we styling today?")
                    .font(.system(size: 15))
                    .foregroundColor(.cleanTextSecondary)
            }
            
            Spacer()
            
            // Profile avatar (uses saved profile image if available)
            ProfileAvatarView(
                profileImagePath: userProfiles.first?.profileImagePath,
                name: userName,
                size: 44
            )
        }
        .padding(.top, CleanDesign.spacingL)
    }
    
    // MARK: - AI Daily Suggestion (Severance Style)
    
    private var aiDailySuggestion: some View {
        HStack(spacing: CleanDesign.spacingM) {
            // Geometric Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.cleanBorder, lineWidth: 1)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "lightbulb")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.cleanOrange)
            }
            
            // Message
            VStack(alignment: .leading, spacing: 4) {
                Text("DAILY TIP")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(.cleanOrange)
                
                Text(dailyTip)
                    .font(.system(size: 14))
                    .foregroundColor(.cleanTextPrimary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(CleanDesign.spacingL)
        .background(Color.cleanCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cleanBorder, lineWidth: 1)
        )
        .onAppear {
            if dailyTip.isEmpty {
                dailyTip = getDailySuggestion()
            }
        }
    }
    
    private func getDailySuggestion() -> String {
        let month = Calendar.current.component(.month, from: Date())
        
        // Seasonal suggestions
        if month >= 11 || month <= 2 {
            // Winter
            let winterTips = [
                "Perfect layering weather. Try a cozy sweater under your coat.",
                "A scarf adds elegance on chilly days.",
                "A warm neutral palette works beautifully this season."
            ]
            return winterTips.randomElement() ?? winterTips[0]
        } else if month >= 3 && month <= 5 {
            // Spring
            let springTips = [
                "Light layers are key—easy to add or remove as needed.",
                "Pastels and florals are timeless for this season.",
                "A tailored jacket completes any spring ensemble."
            ]
            return springTips.randomElement() ?? springTips[0]
        } else if month >= 6 && month <= 8 {
            // Summer
            let summerTips = [
                "Keep it breezy with light, breathable fabrics.",
                "Linen is your most elegant choice in the warmth.",
                "Neutral tones photograph beautifully in summer light."
            ]
            return summerTips.randomElement() ?? summerTips[0]
        } else {
            // Fall
            let fallTips = [
                "Earth tones and layers create timeless autumn elegance.",
                "A refined jacket is essential for transitional weather.",
                "Time for textured knits and warm accessories."
            ]
            return fallTips.randomElement() ?? fallTips[0]
        }
    }
    
    // MARK: - Prompt Section
    
    private var occasionSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundColor(.cleanOrange)
                
                Text("Quick Suggestions")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.cleanTextPrimary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CleanDesign.spacingS) {
                    ForEach(suggestedOccasions.isEmpty ? defaultOccasions : suggestedOccasions) { occasion in
                        Button(action: {
                            viewModel.prompt = occasion.prompt
                            HapticFeedback.selection()
                        }) {
                            Text(occasion.label)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(viewModel.prompt == occasion.prompt ? .white : .cleanTextPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusFull)
                                        .fill(viewModel.prompt == occasion.prompt ? Color.cleanOrange : Color.cleanCardBg)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusFull)
                                        .stroke(Color.cleanBorder, lineWidth: viewModel.prompt == occasion.prompt ? 0 : 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
    
    private var defaultOccasions: [OccasionSuggestion] {
        let month = Calendar.current.component(.month, from: Date())
        let hour = Calendar.current.component(.hour, from: Date())
        
        var occasions: [OccasionSuggestion] = []
        
        // Time-based
        if hour >= 6 && hour < 12 {
            occasions.append(OccasionSuggestion(id: "morning", label: "Morning Coffee", prompt: "casual morning outfit for coffee"))
            occasions.append(OccasionSuggestion(id: "work", label: "Work Day", prompt: "professional work outfit"))
        } else if hour >= 12 && hour < 17 {
            occasions.append(OccasionSuggestion(id: "lunch", label: "Lunch Date", prompt: "smart casual lunch date outfit"))
            occasions.append(OccasionSuggestion(id: "meeting", label: "Business Meeting", prompt: "professional meeting outfit"))
        } else if hour >= 17 && hour < 21 {
            occasions.append(OccasionSuggestion(id: "datenight", label: "Date Night", prompt: "romantic date night outfit"))
            occasions.append(OccasionSuggestion(id: "dinner", label: "Dinner Out", prompt: "elegant dinner outfit"))
        } else {
            occasions.append(OccasionSuggestion(id: "nightout", label: "Night Out", prompt: "stylish night out outfit"))
            occasions.append(OccasionSuggestion(id: "lounge", label: "Cozy Night In", prompt: "comfortable loungewear outfit"))
        }
        
        // Season-based
        if month >= 12 || month <= 2 {
            occasions.append(OccasionSuggestion(id: "winter", label: "Winter Warm", prompt: "warm winter layered outfit"))
            occasions.append(OccasionSuggestion(id: "holiday", label: "Holiday Party", prompt: "festive holiday party outfit"))
        } else if month >= 3 && month <= 5 {
            occasions.append(OccasionSuggestion(id: "spring", label: "Spring Fresh", prompt: "fresh spring outfit with light layers"))
            occasions.append(OccasionSuggestion(id: "brunch", label: "Sunday Brunch", prompt: "stylish brunch outfit"))
        } else if month >= 6 && month <= 8 {
            occasions.append(OccasionSuggestion(id: "summer", label: "Summer Cool", prompt: "cool summer outfit for hot weather"))
            occasions.append(OccasionSuggestion(id: "beach", label: "Beach Day", prompt: "beach ready casual outfit"))
        } else {
            occasions.append(OccasionSuggestion(id: "fall", label: "Fall Vibes", prompt: "cozy fall outfit with earth tones"))
            occasions.append(OccasionSuggestion(id: "football", label: "Game Day", prompt: "sporty casual game day outfit"))
        }
        
        // Always available
        occasions.append(OccasionSuggestion(id: "casual", label: "Casual Day", prompt: "relaxed casual everyday outfit"))
        occasions.append(OccasionSuggestion(id: "gym", label: "Workout", prompt: "athletic gym workout outfit"))
        
        return occasions
    }
    
    private func loadSuggestedOccasions() {
        Task {
            do {
                let suggestions = try await FitoBackendService.shared.fetchSuggestions()
                await MainActor.run {
                    suggestedOccasions = suggestions
                }
            } catch {
                // Use default occasions if API fails
                print("Failed to load suggestions: \(error)")
            }
        }
    }
    
    private var promptSection: some View {
        CleanPromptInput(
            text: $viewModel.prompt,
            placeholder: "I need an outfit for date night at a sushi bar..."
        )
        .focused($isPromptFocused)
    }
    
    // MARK: - Style Me Button (Severance Style)
    
    private var styleMeButton: some View {
        Button(action: generateOutfit) {
            HStack(spacing: 10) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 16, weight: .medium))
                Text("STYLE ME")
                    .font(.system(size: 14, weight: .semibold))
                    .tracking(1)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.cleanOrange)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(viewModel.prompt.isEmpty || viewModel.isGenerating)
        .opacity(viewModel.prompt.isEmpty ? 0.5 : 1)
    }
    
    // MARK: - Generated Look Section
    
    private func generatedLookSection(outfit: HomeViewModel.GeneratedOutfit) -> some View {
        VStack(alignment: .leading, spacing: CleanDesign.spacingM) {
            // Header
            HStack {
                Text("GENERATED LOOK")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cleanTextSecondary)
                    .tracking(0.5)
                
                Spacer()
                
                Text("Just now")
                    .font(.system(size: 12))
                    .foregroundColor(.cleanTextTertiary)
            }
            
            // Outfit Grid - Main item large, others in column
            HStack(alignment: .top, spacing: CleanDesign.spacingM) {
                // Main item (outerwear or top)
                if let mainItem = outfit.outerwear ?? outfit.top {
                    outfitItemView(item: mainItem, size: 160)
                }
                
                // Supporting items column
                VStack(spacing: CleanDesign.spacingS) {
                    if let bottom = outfit.bottom {
                        outfitItemView(item: bottom, size: 72)
                    }
                    if let shoes = outfit.shoes {
                        outfitItemView(item: shoes, size: 72)
                    }
                    if outfit.outerwear != nil, let top = outfit.top {
                        outfitItemView(item: top, size: 72)
                    }
                }
            }
            
            // AI Reasoning
            if let reasoning = viewModel.aiReasoning {
                VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(.cleanOrange)
                        Text("Fito says:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.cleanOrange)
                    }
                    
                    Text(reasoning)
                        .font(.system(size: 14))
                        .foregroundColor(.cleanTextSecondary)
                        .lineSpacing(3)
                    
                    if let tip = viewModel.aiStyleTip {
                        Text(tip)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.cleanTextTertiary)
                            .italic()
                            .padding(.top, 4)
                    }
                }
                .padding(.top, CleanDesign.spacingS)
            }
            
            // Action buttons
            HStack(spacing: CleanDesign.spacingXL) {
                Button(action: {
                    if !hasBeenSaved {
                        // Check saved outfit limit for free users
                        let savedLimit = 3
                        if !subscriptionService.hasActiveSubscription && savedOutfits.count >= savedLimit {
                            showingUpgradeForSave = true
                            HapticFeedback.error()
                            return
                        }
                        
                        HapticFeedback.success()
                        _ = viewModel.saveOutfit(to: modelContext)
                        withAnimation(.spring(response: 0.3)) {
                            hasBeenSaved = true
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: hasBeenSaved ? "heart.fill" : "heart")
                        Text(hasBeenSaved ? "Saved" : "Save")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(hasBeenSaved ? .cleanOrange : .cleanTextSecondary)
                }
                .disabled(hasBeenSaved)
                
                Spacer()
                
                Button(action: {
                    HapticFeedback.medium()
                    viewModel.regenerate(from: clothingItems)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Regenerate")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.cleanOrange)
                }
            }
            .padding(.top, CleanDesign.spacingS)
        }
        .padding(CleanDesign.spacingL)
        .background(Color.cleanCardBg)
        .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusL))
        .shadow(color: .cleanShadow, radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Outfit Item View
    
    private func outfitItemView(item: ClothingItem, size: CGFloat) -> some View {
        OutfitItemImageView(item: item)
            .frame(width: size, height: size)
            .background(Color.cleanBackground)
            .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM))
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        HStack(spacing: CleanDesign.spacingM) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.cleanTextPrimary)
        }
        .padding(CleanDesign.spacingL)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM))
    }
    
    // MARK: - Empty Closet Prompt
    
    private var emptyClosetPrompt: some View {
        VStack(spacing: CleanDesign.spacingL) {
            Image(systemName: "hanger")
                .font(.system(size: 48))
                .foregroundColor(.cleanTextTertiary)
            
            Text("Your closet is empty")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.cleanTextPrimary)
            
            Text("Add some clothes to get started with AI styling")
                .font(.system(size: 14))
                .foregroundColor(.cleanTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CleanDesign.spacingXXL)
        .background(Color.cleanCardBg)
        .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusL))
        .shadow(color: .cleanShadow, radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Loading Overlay (Severance Style with Haptics)
    
    private var loadingOverlay: some View {
        ZStack {
            // Stark white overlay
            Color.white.opacity(0.95)
                .ignoresSafeArea()
            
            // Severance-style loading card
            VStack(spacing: 32) {
                // Geometric animation container
                ZStack {
                    // Outer rotating square
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cleanBorder, lineWidth: 1)
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(viewModel.isGenerating ? 360 : 0))
                        .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: viewModel.isGenerating)
                    
                    // Middle rotating square (opposite direction)
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cleanOrange.opacity(0.5), lineWidth: 1)
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(viewModel.isGenerating ? -360 : 0))
                        .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: viewModel.isGenerating)
                    
                    // Inner pulsing square
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.cleanOrange.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .scaleEffect(viewModel.isGenerating ? 1.1 : 0.9)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: viewModel.isGenerating)
                    
                    // Center icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 24))
                        .foregroundColor(.cleanOrange)
                        .scaleEffect(viewModel.isGenerating ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel.isGenerating)
                }
                .onAppear {
                    startHapticSequence()
                }
                
                // Text content
                VStack(spacing: 12) {
                    Text("GENERATING OUTFIT")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.cleanTextPrimary)
                    
                    Text(viewModel.loadingMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.cleanTextSecondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                        .id(viewModel.loadingMessage)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.loadingMessage)
                }
                
                // Progress dots
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.cleanOrange)
                            .frame(width: 8, height: 8)
                            .scaleEffect(viewModel.isGenerating ? 1.0 : 0.5)
                            .opacity(viewModel.isGenerating ? 1.0 : 0.3)
                            .animation(
                                .easeInOut(duration: 0.4)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                                value: viewModel.isGenerating
                            )
                    }
                }
            }
            .padding(48)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.cleanBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 20, y: 8)
        }
    }
    
    // Haptic sequence during generation
    private func startHapticSequence() {
        // Initial strong feedback
        HapticFeedback.medium()
        
        // Subtle pulsing haptics every 1.5 seconds
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            if viewModel.isGenerating {
                HapticFeedback.light()
            } else {
                timer.invalidate()
                // Success haptic when done
                HapticFeedback.success()
            }
        }
    }
    
    // MARK: - Generate Outfit
    
    private func generateOutfit() {
        isPromptFocused = false
        hasBeenSaved = false  // Reset save state for new outfit
        HapticFeedback.medium()
        viewModel.generateOutfit(from: clothingItems)
    }
}

// MARK: - Outfit Item Image View

struct OutfitItemImageView: View {
    let item: ClothingItem
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            Color.cleanBackground
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: item.category.icon)
                    .font(.title2)
                    .foregroundColor(.cleanTextTertiary)
            }
        }
        .onAppear { loadImage() }
    }
    
    private func loadImage() {
        let path = item.imagePath
        guard !path.isEmpty else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedImage = ImageManager.shared.loadImage(from: path)
            DispatchQueue.main.async {
                self.image = loadedImage
            }
        }
    }
}

// MARK: - Floating Clothing Icon

struct FloatingClothingIcon: View {
    let icon: String
    let index: Int
    let isAnimating: Bool
    
    private var angle: Double {
        Double(index) * (360.0 / 6.0)
    }
    
    private var radius: CGFloat { 55 }
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.cleanOrange.opacity(0.8))
            .offset(
                x: radius * cos(CGFloat(angle + (isAnimating ? 360 : 0)) * .pi / 180),
                y: radius * sin(CGFloat(angle + (isAnimating ? 360 : 0)) * .pi / 180)
            )
            .scaleEffect(isAnimating ? 1.2 : 0.8)
            .opacity(isAnimating ? 1 : 0.5)
            .animation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.15),
                value: isAnimating
            )
    }
}

#Preview {
    CleanHomeView()
        .modelContainer(for: [ClothingItem.self, Outfit.self, UserProfile.self], inMemory: true)
}

// MARK: - Pinterest Inspiration Card

struct PinterestInspirationCard: View {
    let inspiration: OutfitInspiration
    let onTap: () -> Void
    
    // Check if we have a real Pinterest image
    private var hasPinterestImage: Bool {
        inspiration.imageUrl != nil && !inspiration.imageUrl!.isEmpty
    }
    
    // Generate a consistent color based on the title
    private var cardGradient: [Color] {
        let gradients: [[Color]] = [
            [Color(red: 0.98, green: 0.85, blue: 0.85), Color(red: 0.95, green: 0.75, blue: 0.75)], // Blush
            [Color(red: 0.85, green: 0.92, blue: 0.98), Color(red: 0.75, green: 0.85, blue: 0.95)], // Sky
            [Color(red: 0.92, green: 0.98, blue: 0.88), Color(red: 0.82, green: 0.95, blue: 0.78)], // Sage
            [Color(red: 0.98, green: 0.95, blue: 0.85), Color(red: 0.95, green: 0.88, blue: 0.75)], // Cream
            [Color(red: 0.95, green: 0.88, blue: 0.98), Color(red: 0.88, green: 0.78, blue: 0.95)], // Lavender
        ]
        let index = abs(inspiration.title.hashValue) % gradients.count
        return gradients[index]
    }
    
    private var occasionEmoji: String {
        let title = inspiration.title.lowercased()
        if title.contains("date") || title.contains("romantic") { return "🌹" }
        if title.contains("work") || title.contains("office") || title.contains("business") { return "💼" }
        if title.contains("casual") || title.contains("street") { return "👟" }
        if title.contains("party") || title.contains("night") { return "✨" }
        if title.contains("summer") || title.contains("beach") { return "☀️" }
        if title.contains("winter") || title.contains("cozy") { return "❄️" }
        if title.contains("elegant") || title.contains("chic") { return "💎" }
        if title.contains("minimal") { return "🤍" }
        return "🔥"
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Image area - real Pinterest image or gradient fallback
                ZStack {
                    if hasPinterestImage, let urlString = inspiration.imageUrl,
                       let url = URL(string: urlString) {
                        // Real Pinterest Image
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.cleanBackground)
                                    .overlay {
                                        ProgressView()
                                            .tint(.cleanOrange)
                                    }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            case .failure:
                                gradientFallback
                            @unknown default:
                                gradientFallback
                            }
                        }
                        

                    } else {
                        // Gradient fallback when no image
                        gradientFallback
                    }
                }
                .frame(width: 160, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Title and info
                VStack(alignment: .leading, spacing: 4) {
                    Text(inspiration.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cleanTextPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Style tag instead of occasion
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9, weight: .bold))
                        Text("For You")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.cleanOrange)
                    
                    Text("Tap to style →")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.cleanTextTertiary)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }
            .background(Color.cleanCardBg)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private var gradientFallback: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: cardGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Emoji badge
                Text(occasionEmoji)
                    .font(.system(size: 36))
                
                Spacer()
                
                // Color palette dots
                if let colors = inspiration.colorPalette, !colors.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(colors.prefix(4), id: \.self) { colorName in
                            Circle()
                                .fill(colorFromName(colorName))
                                .frame(width: 14, height: 14)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1.5)
                                )
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
    
    private func colorFromName(_ name: String) -> Color {
        let lowered = name.lowercased()
        switch lowered {
        case "black": return .black
        case "white": return .white
        case "red", "crimson", "scarlet": return .red
        case "blue", "navy", "cobalt": return Color(red: 0.2, green: 0.3, blue: 0.7)
        case "green", "olive", "sage", "forest": return Color(red: 0.4, green: 0.6, blue: 0.4)
        case "yellow", "gold", "mustard": return Color(red: 0.9, green: 0.8, blue: 0.3)
        case "orange", "rust", "terracotta": return .orange
        case "purple", "violet", "plum": return .purple
        case "pink", "blush", "rose": return Color(red: 1.0, green: 0.7, blue: 0.8)
        case "brown", "tan", "camel", "chocolate": return Color(red: 0.6, green: 0.4, blue: 0.3)
        case "gray", "grey", "charcoal": return .gray
        case "beige", "cream", "ivory": return Color(red: 0.96, green: 0.93, blue: 0.87)
        default: return .gray
        }
    }
}

// MARK: - Occasion Suggestion Model

struct OccasionSuggestion: Identifiable, Codable {
    let id: String
    let label: String
    let prompt: String
}

