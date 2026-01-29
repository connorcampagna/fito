//
//  AuthService.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  Authentication & Account Management
//

import Foundation
import CryptoKit
import UIKit

// MARK: - Auth Service

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: FitoUser?
    @Published var isLoading = false
    @Published var error: AuthError?
    
    // Auth tokens for API calls
    private(set) var authToken: String?
    private(set) var refreshToken: String?
    
    // Backend mode - set to false for local-only auth
    private let useBackend = true
    
    private let keychain = KeychainHelper.shared
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadSavedUser()
        loadAuthTokens()
        
        // Set up token refresh if using backend
        if useBackend {
            Task {
                await refreshTokenIfNeeded()
            }
        }
    }
    
    private func loadAuthTokens() {
        authToken = try? keychain.load(forKey: "fito_auth_token")
        refreshToken = try? keychain.load(forKey: "fito_refresh_token")
    }
    
    private func saveAuthTokens(access: String, refresh: String) {
        try? keychain.save(access, forKey: "fito_auth_token")
        try? keychain.save(refresh, forKey: "fito_refresh_token")
        authToken = access
        self.refreshToken = refresh
    }
    
    private func clearAuthTokens() {
        try? keychain.delete(forKey: "fito_auth_token")
        try? keychain.delete(forKey: "fito_refresh_token")
        authToken = nil
        refreshToken = nil
    }
    
    // MARK: - Token Refresh
    
    func refreshTokenIfNeeded() async {
        guard useBackend,
              let refresh = refreshToken else { return }
        
        do {
            let response = try await FitoBackendService.shared.refreshToken(refresh)
            saveAuthTokens(access: response.accessToken, refresh: response.refreshToken)
            
            // Update current user from response
            var user = FitoUser(
                id: response.user.id,
                email: response.user.email,
                displayName: response.user.name ?? "Stylist",
                avatarURL: nil,
                createdAt: Date(),
                authMethod: response.user.isGuest ? .guest : .email
            )
            
            // Fetch full profile to get gender and ageRange
            if let profile = try? await FitoBackendService.shared.getProfile(authToken: response.accessToken) {
                user.gender = profile.gender
                user.ageRange = profile.ageRange
                user.profileCompleted = profile.profileCompleted
                if let name = profile.name, !name.isEmpty {
                    user.displayName = name
                }
            }
            
            currentUser = user
            isAuthenticated = true
            
            // Save locally for offline access
            if let userData = try? JSONEncoder().encode(user) {
                userDefaults.set(userData, forKey: "current_user")
            }
        } catch {
            // Token refresh failed - user needs to re-authenticate
            print("Token refresh failed: \(error)")
        }
    }
    
    // MARK: - User Model
    
    struct FitoUser: Codable, Identifiable {
        let id: String
        var email: String?
        var displayName: String
        var avatarURL: String?
        var createdAt: Date
        var authMethod: AuthMethod
        var gender: String?
        var ageRange: String?
        var profileCompleted: Bool
        
        enum AuthMethod: String, Codable {
            case email
            case guest
        }
        
        var isGuest: Bool {
            authMethod == .guest
        }
        
        var needsProfileSetup: Bool {
            !profileCompleted && !isGuest
        }
        
        init(id: String, email: String?, displayName: String, avatarURL: String? = nil, createdAt: Date, authMethod: AuthMethod, gender: String? = nil, ageRange: String? = nil, profileCompleted: Bool = false) {
            self.id = id
            self.email = email
            self.displayName = displayName
            self.avatarURL = avatarURL
            self.createdAt = createdAt
            self.authMethod = authMethod
            self.gender = gender
            self.ageRange = ageRange
            self.profileCompleted = profileCompleted
        }
    }
    
    // MARK: - Email Auth
    
    func signUp(email: String, password: String, name: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Validate
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 8 else {
            throw AuthError.weakPassword
        }
        
        if useBackend {
            // Use backend API
            do {
                let response = try await FitoBackendService.shared.register(
                    email: email,
                    password: password,
                    name: name
                )
                
                saveAuthTokens(access: response.accessToken, refresh: response.refreshToken)
                
                let user = FitoUser(
                    id: response.user.id,
                    email: response.user.email,
                    displayName: response.user.name ?? name,
                    avatarURL: nil,
                    createdAt: Date(),
                    authMethod: .email
                )
                
                // Save locally for offline access
                let userData = try JSONEncoder().encode(user)
                userDefaults.set(userData, forKey: "current_user")
                userDefaults.set(email, forKey: "current_session")
                
                currentUser = user
                isAuthenticated = true
            } catch BackendError.apiError(let message) {
                if message.lowercased().contains("already") {
                    throw AuthError.emailAlreadyInUse
                }
                throw AuthError.networkError
            } catch {
                throw AuthError.networkError
            }
        } else {
            // Local-only auth (fallback)
            let emailHash = hashEmail(email)
            if userDefaults.data(forKey: "user_\(emailHash)") != nil {
                throw AuthError.emailAlreadyInUse
            }
            
            let user = FitoUser(
                id: UUID().uuidString,
                email: email,
                displayName: name,
                avatarURL: nil,
                createdAt: Date(),
                authMethod: .email
            )
            
            let passwordHash = hashPassword(password)
            try keychain.save(passwordHash, forKey: "pwd_\(emailHash)")
            try saveUser(user, emailHash: emailHash)
            
            let token = generateAuthToken(for: user)
            saveAuthTokens(access: token, refresh: token)
            
            currentUser = user
            isAuthenticated = true
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        if useBackend {
            // Use backend API
            do {
                let response = try await FitoBackendService.shared.login(
                    email: email,
                    password: password
                )
                
                saveAuthTokens(access: response.accessToken, refresh: response.refreshToken)
                
                var user = FitoUser(
                    id: response.user.id,
                    email: response.user.email,
                    displayName: response.user.name ?? "Stylist",
                    avatarURL: nil,
                    createdAt: Date(),
                    authMethod: .email
                )
                
                // Fetch full profile from backend to get gender and ageRange
                if let profile = try? await FitoBackendService.shared.getProfile(authToken: response.accessToken) {
                    user.gender = profile.gender
                    user.ageRange = profile.ageRange
                    user.profileCompleted = profile.profileCompleted
                    if let name = profile.name, !name.isEmpty {
                        user.displayName = name
                    }
                }
                
                // Save locally for offline access
                let userData = try JSONEncoder().encode(user)
                userDefaults.set(userData, forKey: "current_user")
                userDefaults.set(email, forKey: "current_session")
                
                currentUser = user
                isAuthenticated = true
            } catch BackendError.apiError(let message) {
                if message.contains("Invalid") {
                    throw AuthError.invalidCredentials
                }
                throw AuthError.networkError
            } catch {
                throw AuthError.networkError
            }
        } else {
            // Local-only auth (fallback)
            let emailHash = hashEmail(email)
            
            guard let storedHash = try? keychain.load(forKey: "pwd_\(emailHash)"),
                  storedHash == hashPassword(password) else {
                throw AuthError.invalidCredentials
            }
            
            guard let userData = userDefaults.data(forKey: "user_\(emailHash)"),
                  let user = try? JSONDecoder().decode(FitoUser.self, from: userData) else {
                throw AuthError.userNotFound
            }
            
            let token = generateAuthToken(for: user)
            saveAuthTokens(access: token, refresh: token)
            
            currentUser = user
            isAuthenticated = true
            userDefaults.set(emailHash, forKey: "current_session")
        }
    }
    
    // MARK: - Guest Mode
    
    func continueAsGuest() async {
        isLoading = true
        defer { isLoading = false }
        
        if useBackend {
            do {
                let response = try await FitoBackendService.shared.createGuestUser()
                
                saveAuthTokens(access: response.accessToken, refresh: response.refreshToken)
                
                let user = FitoUser(
                    id: response.user.id,
                    email: nil,
                    displayName: "Guest Stylist",
                    avatarURL: nil,
                    createdAt: Date(),
                    authMethod: .guest
                )
                
                // Save locally
                if let userData = try? JSONEncoder().encode(user) {
                    userDefaults.set(userData, forKey: "current_user")
                    userDefaults.set("guest", forKey: "current_session")
                }
                
                currentUser = user
                isAuthenticated = true
            } catch {
                // Fall back to local guest if backend fails
                createLocalGuest()
            }
        } else {
            createLocalGuest()
        }
    }
    
    private func createLocalGuest() {
        let user = FitoUser(
            id: UUID().uuidString,
            email: nil,
            displayName: "Guest Stylist",
            avatarURL: nil,
            createdAt: Date(),
            authMethod: .guest
        )
        
        currentUser = user
        isAuthenticated = true
        
        let token = generateAuthToken(for: user)
        saveAuthTokens(access: token, refresh: token)
        
        if let userData = try? JSONEncoder().encode(user) {
            userDefaults.set(userData, forKey: "guest_user")
            userDefaults.set("guest", forKey: "current_session")
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        clearAuthTokens()
        userDefaults.removeObject(forKey: "current_session")
        userDefaults.removeObject(forKey: "current_user")
    }
    
    // MARK: - Update Profile
    
    func updateDisplayName(_ name: String) throws {
        guard var user = currentUser else { return }
        user.displayName = name
        
        switch user.authMethod {
        case .email:
            if let email = user.email {
                try saveUser(user, emailHash: hashEmail(email))
            }
        case .guest:
            let userData = try JSONEncoder().encode(user)
            userDefaults.set(userData, forKey: "guest_user")
        }
        
        currentUser = user
    }
    
    // MARK: - Complete Profile Setup
    
    func completeProfileSetup(name: String?, gender: String, ageRange: String, profileImageData: Data?) async throws {
        guard var user = currentUser else { return }
        
        if let name = name, !name.isEmpty {
            user.displayName = name
        }
        user.gender = gender
        user.ageRange = ageRange
        user.profileCompleted = true
        
        var uploadedImageUrl: String? = nil
        
        // Upload profile image to backend if provided
        if let imageData = profileImageData,
           let image = UIImage(data: imageData) {
            // Save locally as backup
            if let path = ImageManager.shared.saveImage(image) {
                user.avatarURL = path
            }
            
            // Upload to backend storage
            if useBackend, let token = authToken {
                do {
                    uploadedImageUrl = try await FitoBackendService.shared.uploadProfileImage(
                        imageData: imageData,
                        authToken: token
                    )
                    // Use backend URL as primary source
                    if let url = uploadedImageUrl {
                        user.avatarURL = url
                    }
                } catch {
                    print("Failed to upload profile image: \(error)")
                    // Continue with local path
                }
            }
        }
        
        // Save to backend if available
        if useBackend, let token = authToken {
            do {
                _ = try await FitoBackendService.shared.completeProfile(
                    name: user.displayName,
                    gender: gender,
                    ageRange: ageRange,
                    profileImage: uploadedImageUrl,
                    authToken: token
                )
            } catch {
                print("Failed to complete profile on backend: \(error)")
                // Continue anyway - save locally
            }
        }
        
        // Save locally
        switch user.authMethod {
        case .email:
            if let email = user.email {
                try saveUser(user, emailHash: hashEmail(email))
            }
        case .guest:
            let userData = try JSONEncoder().encode(user)
            userDefaults.set(userData, forKey: "guest_user")
        }
        
        currentUser = user
    }
    
    // MARK: - Delete Account
    
    func deleteAccount() throws {
        guard let user = currentUser else { return }
        
        switch user.authMethod {
        case .email:
            if let email = user.email {
                let emailHash = hashEmail(email)
                userDefaults.removeObject(forKey: "user_\(emailHash)")
                try? keychain.delete(forKey: "pwd_\(emailHash)")
            }
        case .guest:
            userDefaults.removeObject(forKey: "guest_user")
        }
        
        signOut()
    }
    
    // MARK: - Private Helpers
    
    private func loadSavedUser() {
        // First try to load from current_user (where backend users are saved)
        if let userData = userDefaults.data(forKey: "current_user"),
           let user = try? JSONDecoder().decode(FitoUser.self, from: userData) {
            currentUser = user
            isAuthenticated = true
            return
        }
        
        // Fallback: Check legacy session-based storage
        guard let session = userDefaults.string(forKey: "current_session") else { return }
        
        if session == "guest" {
            if let userData = userDefaults.data(forKey: "guest_user"),
               let user = try? JSONDecoder().decode(FitoUser.self, from: userData) {
                currentUser = user
                isAuthenticated = true
            }
        } else if session.hasPrefix("apple_") {
            if let userData = userDefaults.data(forKey: session),
               let user = try? JSONDecoder().decode(FitoUser.self, from: userData) {
                currentUser = user
                isAuthenticated = true
            }
        } else {
            if let userData = userDefaults.data(forKey: "user_\(session)"),
               let user = try? JSONDecoder().decode(FitoUser.self, from: userData) {
                currentUser = user
                isAuthenticated = true
            }
        }
    }
    
    private func saveUser(_ user: FitoUser, emailHash: String) throws {
        let userData = try JSONEncoder().encode(user)
        userDefaults.set(userData, forKey: "user_\(emailHash)")
        userDefaults.set(emailHash, forKey: "current_session")
    }
    
    private func hashEmail(_ email: String) -> String {
        let data = Data(email.lowercased().utf8)
        let hash = SHA256.hash(data: data)
        return hash.prefix(16).map { String(format: "%02x", $0) }.joined()
    }
    
    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let regex = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/
            .ignoresCase()
        return email.contains(regex)
    }
    
    private func generateAuthToken(for user: FitoUser) -> String {
        // Generate a secure token with user info and timestamp
        let timestamp = Int(Date().timeIntervalSince1970)
        let tokenData = "\(user.id).\(timestamp).\(UUID().uuidString)"
        let tokenBytes = Data(tokenData.utf8)
        let hash = SHA256.hash(data: tokenBytes)
        let signature = hash.map { String(format: "%02x", $0) }.joined()
        
        // Create a base64-encoded token with payload
        let payload = "\(user.id):\(timestamp):\(signature.prefix(32))"
        return Data(payload.utf8).base64EncodedString()
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case invalidCredentials
    case userNotFound
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 8 characters."
        case .emailAlreadyInUse:
            return "An account with this email already exists."
        case .invalidCredentials:
            return "Invalid email or password."
        case .userNotFound:
            return "Account not found."
        case .networkError:
            return "Network error. Please check your connection."
        }
    }
}

// MARK: - Keychain Helper

final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}
    
    func save(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }
    
    func load(forKey key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    enum KeychainError: Error {
        case saveFailed
        case loadFailed
    }
}
