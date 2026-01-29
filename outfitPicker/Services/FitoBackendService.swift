//
//  FitoBackendService.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  Secure Backend Proxy Service
//
//  IMPORTANT: You need to deploy a backend server that holds your OpenAI API key.
//  This service communicates with YOUR backend, which then calls OpenAI.
//  This keeps your API key secure and allows you to control usage/billing.
//

import Foundation

// MARK: - Backend Configuration

enum FitoConfig {
    // Your deployed Vercel backend URL
    static let backendURL = "https://fito-nine.vercel.app/api"
    
    static let appVersion = "1.0.0"
    static let bundleId = Bundle.main.bundleIdentifier ?? "com.fito.app"
}

// MARK: - Backend Service

actor FitoBackendService {
    static let shared = FitoBackendService()
    
    private init() {}
    
    // MARK: - Generate Outfit (Proxied through your backend)
    
    func generateOutfit(
        userId: String,
        authToken: String,
        prompt: String,
        clothingItems: [ClothingItemDTO]
    ) async throws -> OutfitSuggestion {
        let endpoint = "\(FitoConfig.backendURL)/generate-outfit"
        
        let body = GenerateOutfitRequest(
            userId: userId,
            prompt: prompt,
            clothingItems: clothingItems
        )
        
        let response: GenerateOutfitResponse = try await makeAuthenticatedRequest(
            endpoint: endpoint,
            method: "POST",
            body: body,
            authToken: authToken
        )
        
        // Check if closet is missing items
        if response.notSuitable == true {
            throw BackendError.apiError(response.reasoning ?? "Missing essential clothing items")
        }
        
        return OutfitSuggestion(
            topId: response.top_id,
            bottomId: response.bottom_id,
            shoesId: response.shoes_id,
            outerwearId: response.outerwear_id,
            reasoning: response.reasoning ?? "Here's a great outfit for you!",
            styleTip: response.style_tip ?? "Style it your way!"
        )
    }
    
    // MARK: - Check Subscription Status
    
    func checkSubscription(userId: String, authToken: String) async throws -> SubscriptionStatus {
        let endpoint = "\(FitoConfig.backendURL)/subscription"
        
        // Backend returns subscription directly, not wrapped
        let response: SubscriptionStatus = try await makeAuthenticatedRequest(
            endpoint: endpoint,
            method: "GET",
            body: Optional<EmptyBody>.none,
            authToken: authToken
        )
        
        return response
    }
    
    // MARK: - Track Usage
    
    func trackUsage(userId: String, authToken: String, action: UsageAction) async throws {
        let endpoint = "\(FitoConfig.backendURL)/usage/track"
        
        let body = TrackUsageRequest(userId: userId, action: action.rawValue)
        
        let _: EmptyResponse = try await makeAuthenticatedRequest(
            endpoint: endpoint,
            method: "POST",
            body: body,
            authToken: authToken
        )
    }
    
    // MARK: - Verify Auth Token
    
    func verifyToken(_ token: String) async throws -> TokenVerification {
        let endpoint = "\(FitoConfig.backendURL)/auth/verify"
        
        let response: TokenVerificationResponse = try await makeAuthenticatedRequest(
            endpoint: endpoint,
            method: "GET",
            body: Optional<EmptyBody>.none,
            authToken: token
        )
        
        return response.verification
    }
    
    // MARK: - Fetch Suggestions (Quick occasion suggestions)
    
    func fetchSuggestions() async throws -> [OccasionSuggestion] {
        let endpoint = "\(FitoConfig.backendURL)/suggestions"
        
        guard let url = URL(string: endpoint) else {
            throw BackendError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BackendError.invalidResponse
        }
        
        let suggestionsResponse = try JSONDecoder().decode(SuggestionsResponse.self, from: data)
        return suggestionsResponse.suggestions
    }
    
    // MARK: - Get Outfit Inspiration (Pinterest-style)
    
    func getOutfitInspiration(
        prompt: String?,
        outfitTags: [String],
        style: String?,
        authToken: String
    ) async throws -> [OutfitInspiration] {
        let endpoint = "\(FitoConfig.backendURL)/outfit-inspiration"
        
        let body = InspirationRequest(
            prompt: prompt,
            outfitTags: outfitTags,
            style: style
        )
        
        let response: InspirationResponse = try await makeAuthenticatedRequest(
            endpoint: endpoint,
            method: "POST",
            body: body,
            authToken: authToken
        )
        
        return response.inspirations
    }
    
    // MARK: - Match Inspiration to User's Clothes
    
    func matchInspiration(
        inspiration: OutfitInspiration,
        clothingItems: [ClothingItemDTO],
        authToken: String
    ) async throws -> OutfitSuggestion {
        let endpoint = "\(FitoConfig.backendURL)/match-inspiration"
        
        let body = MatchInspirationRequest(
            inspiration: inspiration,
            clothingItems: clothingItems
        )
        
        let response: MatchInspirationResponse = try await makeAuthenticatedRequest(
            endpoint: endpoint,
            method: "POST",
            body: body,
            authToken: authToken
        )
        
        return OutfitSuggestion(
            topId: response.top_id,
            bottomId: response.bottom_id,
            shoesId: response.shoes_id,
            outerwearId: response.outerwear_id,
            reasoning: response.reasoning,
            styleTip: response.style_tip,
            matchScore: response.matchScore
        )
    }
    
    // MARK: - Private Helpers
    
    // MARK: - Image Analysis (GPT-4 Vision)
    
    func analyzeImage(
        imageBase64: String,
        category: String?,
        authToken: String
    ) async throws -> ImageAnalysisResult {
        let endpoint = "\(FitoConfig.backendURL)/analyze-image"
        
        let body = AnalyzeImageRequest(
            imageBase64: imageBase64,
            category: category
        )
        
        let response: ImageAnalysisResult = try await makeAuthenticatedRequest(
            endpoint: endpoint,
            method: "POST",
            body: body,
            authToken: authToken
        )
        
        return response
    }
    
    // MARK: - Subscription Methods
    
    /// Get current subscription status from backend
    func getSubscriptionStatus(authToken: String) async throws -> SubscriptionStatusDTO {
        let endpoint = "\(FitoConfig.backendURL)/subscription"
        
        let response: SubscriptionStatusDTO = try await makeAuthenticatedRequest(
            endpoint: endpoint,
            method: "GET",
            body: Optional<EmptyBody>.none,
            authToken: authToken
        )
        
        return response
    }
    
    /// Get available subscription plans
    func getSubscriptionPlans(authToken: String) async throws -> SubscriptionPlansResponse {
        let endpoint = "\(FitoConfig.backendURL)/subscription/plans"
        
        let response: SubscriptionPlansResponse = try await makeAuthenticatedRequest(
            endpoint: endpoint,
            method: "GET",
            body: Optional<EmptyBody>.none,
            authToken: authToken
        )
        
        return response
    }
    
    /// Create Stripe checkout session (for web-based checkout)
    func createCheckoutSession(tier: String, authToken: String) async throws -> CheckoutSessionResponse {
        let endpoint = "\(FitoConfig.backendURL)/subscription/checkout"
        
        let body = CheckoutRequest(tier: tier)
        
        let response: CheckoutSessionResponse = try await makeAuthenticatedRequest(
            endpoint: endpoint,
            method: "POST",
            body: body,
            authToken: authToken
        )
        
        return response
    }
    
    /// Verify Apple IAP purchase with backend
    func verifyApplePurchase(productId: String, authToken: String) async throws -> ApplePurchaseVerificationResponse {
        let endpoint = "\(FitoConfig.backendURL)/subscription/verify-apple"
        
        let body = ApplePurchaseVerificationRequest(
            productId: productId,
            bundleId: FitoConfig.bundleId
        )
        
        let response: ApplePurchaseVerificationResponse = try await makeAuthenticatedRequest(
            endpoint: endpoint,
            method: "POST",
            body: body,
            authToken: authToken
        )
        
        return response
    }
    
    /// Get Stripe customer portal URL
    func getCustomerPortalURL(authToken: String) async throws -> CustomerPortalResponse {
        let endpoint = "\(FitoConfig.backendURL)/subscription/portal"
        
        let response: CustomerPortalResponse = try await makeAuthenticatedRequest(
            endpoint: endpoint,
            method: "POST",
            body: Optional<EmptyBody>.none,
            authToken: authToken
        )
        
        return response
    }
    
    // MARK: - Auth Methods
    
    /// Register a new user
    func register(email: String, password: String, name: String?) async throws -> AuthResponse {
        let endpoint = "\(FitoConfig.backendURL)/auth/register"
        
        let body = RegisterRequest(email: email, password: password, name: name)
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw BackendError.apiError(errorResponse.message)
            }
            throw BackendError.invalidResponse
        }
        
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    /// Login with email/password
    func login(email: String, password: String) async throws -> AuthResponse {
        let endpoint = "\(FitoConfig.backendURL)/auth/login"
        
        let body = LoginRequest(email: email, password: password)
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw BackendError.apiError(errorResponse.message)
            }
            throw BackendError.invalidResponse
        }
        
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    /// Refresh access token
    func refreshToken(_ refreshToken: String) async throws -> AuthResponse {
        let endpoint = "\(FitoConfig.backendURL)/auth/refresh"
        
        let body = RefreshTokenRequest(refreshToken: refreshToken)
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw BackendError.unauthorized
        }
        
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    /// Continue as guest
    func createGuestUser() async throws -> AuthResponse {
        let endpoint = "\(FitoConfig.backendURL)/auth/guest"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw BackendError.invalidResponse
        }
        
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    // MARK: - Profile Methods
    
    /// Get user profile
    func getProfile(authToken: String) async throws -> ProfileDTO {
        let endpoint = "\(FitoConfig.backendURL)/profile"
        
        let response: ProfileDTO = try await makeAuthenticatedRequest(
            endpoint: endpoint,
            method: "GET",
            body: Optional<EmptyBody>.none,
            authToken: authToken
        )
        
        return response
    }
    
    /// Update user profile
    func updateProfile(
        name: String?,
        gender: String?,
        ageRange: String?,
        profileImage: String?,
        authToken: String
    ) async throws -> ProfileDTO {
        let endpoint = "\(FitoConfig.backendURL)/profile"
        
        let body = UpdateProfileRequest(
            name: name,
            gender: gender,
            ageRange: ageRange,
            profileImage: profileImage
        )
        
        let response: ProfileDTO = try await makeAuthenticatedRequest(
            endpoint: endpoint,
            method: "PUT",
            body: body,
            authToken: authToken
        )
        
        return response
    }
    
    /// Complete profile setup (after signup)
    func completeProfile(
        name: String?,
        gender: String,
        ageRange: String,
        profileImage: String?,
        authToken: String
    ) async throws -> CompleteProfileResponse {
        let endpoint = "\(FitoConfig.backendURL)/profile/complete"
        
        let body = CompleteProfileRequest(
            name: name,
            gender: gender,
            ageRange: ageRange,
            profileImage: profileImage
        )
        
        let response: CompleteProfileResponse = try await makeAuthenticatedRequest(
            endpoint: endpoint,
            method: "POST",
            body: body,
            authToken: authToken
        )
        
        return response
    }
    
    /// Upload profile image to storage
    func uploadProfileImage(
        imageData: Data,
        authToken: String
    ) async throws -> String {
        let endpoint = "\(FitoConfig.backendURL)/profile/image"
        
        let base64String = imageData.base64EncodedString()
        let body = UploadImageRequest(imageBase64: base64String)
        
        let response: UploadImageResponse = try await makeAuthenticatedRequest(
            endpoint: endpoint,
            method: "POST",
            body: body,
            authToken: authToken
        )
        
        return response.imageUrl
    }
    
    // MARK: - Export User Data (GDPR)
    
    func exportUserData(authToken: String) async throws -> Data {
        let endpoint = "\(FitoConfig.backendURL)/account/export"
        
        guard let url = URL(string: endpoint) else {
            throw BackendError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60 // Allow more time for data export
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            throw BackendError.unauthorized
        default:
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw BackendError.apiError(errorResponse.message)
            }
            throw BackendError.unknown
        }
    }
    
    // MARK: - Delete Account (App Store Requirement)
    
    func deleteAccount(authToken: String) async throws {
        let endpoint = "\(FitoConfig.backendURL)/account"
        
        guard let url = URL(string: endpoint) else {
            throw BackendError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return // Success
        case 401:
            throw BackendError.unauthorized
        default:
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw BackendError.apiError(errorResponse.message)
            }
            throw BackendError.unknown
        }
    }
    
    // MARK: - Helper Methods
    
    private func makeAuthenticatedRequest<T: Encodable, R: Decodable>(
        endpoint: String,
        method: String,
        body: T?,
        authToken: String
    ) async throws -> R {
        guard let url = URL(string: endpoint) else {
            throw BackendError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue(FitoConfig.appVersion, forHTTPHeaderField: "X-App-Version")
        request.setValue(FitoConfig.bundleId, forHTTPHeaderField: "X-Bundle-Id")
        request.timeoutInterval = 30
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(R.self, from: data)
        case 401:
            throw BackendError.unauthorized
        case 402:
            throw BackendError.subscriptionRequired
        case 429:
            throw BackendError.rateLimited
        case 500...599:
            throw BackendError.serverError
        default:
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw BackendError.apiError(errorResponse.message)
            }
            throw BackendError.unknown
        }
    }
}

// MARK: - Request/Response Models

struct GenerateOutfitRequest: Codable {
    let userId: String
    let prompt: String
    let clothingItems: [ClothingItemDTO]
}

struct GenerateOutfitResponse: Codable {
    let top_id: String?
    let bottom_id: String?
    let shoes_id: String?
    let outerwear_id: String?
    let reasoning: String?
    let style_tip: String?
    let notSuitable: Bool?
    let missingCategories: [String]?
}

// Legacy structs kept for compatibility
struct OutfitResponseData: Codable {
    let topId: String?
    let bottomId: String?
    let shoesId: String?
    let outerwearId: String?
    let reasoning: String
    let styleTip: String
}

struct UsageData: Codable {
    let requestsUsed: Int
    let requestsRemaining: Int
    let resetDate: Date?
}

struct SubscriptionStatusResponse: Codable {
    let subscription: SubscriptionStatus
}

struct SubscriptionStatus: Codable {
    let tier: String  // "FREE", "PREMIUM"
    let status: String // "ACTIVE", "CANCELED", "PAST_DUE"
    let monthlyLimit: StringOrInt  // Backend sends "Unlimited" or number
    let monthlyUsed: Int
    let features: [String]?
    let currentPeriodEnd: String?
    let cancelAtPeriodEnd: Bool?
    
    var isActive: Bool {
        status == "ACTIVE"
    }
    
    /// Returns remaining generations for this month
    var requestsRemaining: Int {
        switch monthlyLimit {
        case .string(let s):
            // "Unlimited" for premium means 100 per month
            if s.lowercased() == "unlimited" {
                return max(0, 100 - monthlyUsed)
            }
            return 0
        case .int(let limit):
            return max(0, limit - monthlyUsed)
        }
    }
    
    /// Returns the monthly limit (100 for premium, 5 for free)
    var requestsLimit: Int {
        switch monthlyLimit {
        case .string: return 100  // Premium = 100/month
        case .int(let limit): return limit
        }
    }
    
    /// True if user has unlimited/premium subscription
    var isUnlimited: Bool {
        if case .string(let s) = monthlyLimit {
            return s.lowercased() == "unlimited"
        }
        return false
    }
}

// Helper enum to decode strings or ints
enum StringOrInt: Codable {
    case string(String)
    case int(Int)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(StringOrInt.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or Int"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        }
    }
}

struct TrackUsageRequest: Codable {
    let userId: String
    let action: String
}

struct AnalyzeImageRequest: Codable {
    let imageBase64: String
    let category: String?
}

struct SuggestionsResponse: Codable {
    let suggestions: [OccasionSuggestion]
}

// MARK: - Inspiration Models

struct InspirationRequest: Codable {
    let prompt: String?
    let outfitTags: [String]
    let style: String?
}

struct InspirationResponse: Codable {
    let inspirations: [OutfitInspiration]
    let source: String?  // "pinterest", "ai", or "fallback"
}

struct OutfitInspiration: Codable, Identifiable {
    var id: String { title + (imageUrl ?? "") }
    let title: String
    let description: String
    let styleNotes: [String]?
    let colorPalette: [String]?
    let occasion: String?
    let season: String?
    let imageUrl: String?   // Real Pinterest image URL
    let pinUrl: String?     // Link to original Pinterest pin
}

struct MatchInspirationRequest: Codable {
    let inspiration: OutfitInspiration
    let clothingItems: [ClothingItemDTO]
}

struct MatchInspirationResponse: Codable {
    let top_id: String?
    let bottom_id: String?
    let shoes_id: String?
    let outerwear_id: String?
    let matchScore: Int?
    let reasoning: String
    let style_tip: String
}

enum UsageAction: String {
    case generateOutfit = "generate_outfit"
    case analyzeClothing = "analyze_clothing"
    case viewHistory = "view_history"
}

struct TokenVerificationResponse: Codable {
    let verification: TokenVerification
}

struct TokenVerification: Codable {
    let isValid: Bool
    let userId: String?
    let expiresAt: Date?
}

struct EmptyBody: Codable {}
struct EmptyResponse: Codable {}

struct ErrorResponse: Codable {
    let message: String
    let code: String?
}

// MARK: - Subscription DTOs

struct SubscriptionStatusDTO: Codable {
    let tier: String
    let status: String
    let monthlyUsed: Int
    let monthlyLimit: Int
    let expiresAt: String?
    let provider: String? // "stripe" or "apple"
}

struct SubscriptionPlansResponse: Codable {
    let plans: [SubscriptionPlanDTO]
}

struct SubscriptionPlanDTO: Codable {
    let tier: String
    let name: String
    let monthlyPrice: Double
    let monthlyLimit: Int
    let features: [String]
    let stripePriceId: String?
    let appleProductId: String?
}

struct CheckoutRequest: Codable {
    let tier: String
}

struct CheckoutSessionResponse: Codable {
    let checkoutUrl: String
    let sessionId: String
}

struct ApplePurchaseVerificationRequest: Codable {
    let productId: String
    let bundleId: String
}

struct ApplePurchaseVerificationResponse: Codable {
    let success: Bool
    let tier: String?
    let expiresAt: String?
}

struct CustomerPortalResponse: Codable {
    let portalUrl: String
}

// MARK: - Auth DTOs

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String?
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: UserDTO
}

struct UserDTO: Codable {
    let id: String
    let email: String?
    let name: String?
    let tier: String
    let isGuest: Bool
    let gender: String?
    let ageRange: String?
    let profileImage: String?
    let profileCompleted: Bool?
}

// MARK: - Profile DTOs

struct ProfileDTO: Codable {
    let id: String
    let email: String?
    let name: String?
    let gender: String?
    let ageRange: String?
    let profileImage: String?
    let profileCompleted: Bool
    let subscription: ProfileSubscriptionDTO?
}

struct ProfileSubscriptionDTO: Codable {
    let tier: String
    let status: String
    let monthlyLimit: Int
    let monthlyUsed: Int
}

struct UpdateProfileRequest: Codable {
    let name: String?
    let gender: String?
    let ageRange: String?
    let profileImage: String?
}

struct CompleteProfileRequest: Codable {
    let name: String?
    let gender: String
    let ageRange: String
    let profileImage: String?
}

struct UploadImageRequest: Codable {
    let imageBase64: String
}

struct UploadImageResponse: Codable {
    let imageUrl: String
}

struct CompleteProfileResponse: Codable {
    let success: Bool
    let user: ProfileDTO
}

// MARK: - Backend Errors

enum BackendError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case subscriptionRequired
    case rateLimited
    case serverError
    case apiError(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "Please sign in to continue"
        case .subscriptionRequired:
            return "Upgrade to Premium for more outfit suggestions"
        case .rateLimited:
            return "You've reached your daily limit. Upgrade for more!"
        case .serverError:
            return "Server is temporarily unavailable"
        case .apiError(let message):
            return message
        case .unknown:
            return "An unexpected error occurred"
        }
    }
}
