//
//  CleanProfileView.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  Clean Profile View with full functionality
//

import SwiftUI
import SwiftData

struct CleanProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var clothingItems: [ClothingItem]
    @Query private var outfits: [Outfit]
    
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingPrivacyPolicy = false
    @State private var showingEditProfile = false
    @State private var showingStylePreferences = false
    @State private var showingMeasurements = false
    @State private var showingSubscription = false
    @State private var showingExportProgress = false
    @State private var exportError: String?
    @State private var showingExportError = false
    @State private var isExporting = false
    @State private var isDeletingAccount = false
    @StateObject private var authService = AuthService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    private var userProfile: UserProfile? {
        userProfiles.first
    }
    
    private var currentUser: AuthService.FitoUser? {
        authService.currentUser
    }
    
    var body: some View {
        ZStack {
            CleanBackground()
            
            ScrollView {
                VStack(spacing: CleanDesign.spacingXL) {
                    // Offline Banner
                    if !networkMonitor.isConnected {
                        OfflineBanner()
                    }
                    
                    // Profile Header
                    profileHeader
                    
                    // Subscription Section
                    subscriptionSection
                    
                    // Styling Profile Section
                    stylingProfileSection
                    
                    // Settings Section
                    settingsSection
                    
                    // Data & Privacy Section
                    dataPrivacySection
                    
                    // Support Section
                    supportSection
                    
                    // Logout Button
                    logoutButton
                    
                    // App Version
                    appVersion
                }
                .padding(.horizontal, CleanDesign.spacingL)
                .padding(.bottom, 120)
            }
        }
        .alert("Sign Out?", isPresented: $showingLogoutAlert) {
            Button("Sign Out", role: .destructive) {
                authService.signOut()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete All Data?", isPresented: $showingDeleteAlert) {
            Button("Delete Everything", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your clothes and outfit history.")
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            privacyPolicySheet
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileSheet(userProfile: userProfile, modelContext: modelContext)
        }
        .sheet(isPresented: $showingStylePreferences) {
            StylePreferencesSheet(userProfile: userProfile)
        }
        .sheet(isPresented: $showingMeasurements) {
            MeasurementsSheet(userProfile: userProfile)
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionPlansView()
        }
    }
    
    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
            Text("SUBSCRIPTION")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.cleanTextTertiary)
                .tracking(0.5)
                .padding(.leading, CleanDesign.spacingS)
            
            if subscriptionService.hasActiveSubscription {
                // Premium user card (Severance style)
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.cleanOrange)
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "star.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text("PREMIUM")
                                    .font(.system(size: 14, weight: .bold))
                                    .tracking(1)
                                    .foregroundColor(.cleanTextPrimary)
                                
                                Text("ACTIVE")
                                    .font(.system(size: 9, weight: .bold))
                                    .tracking(0.5)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            
                            if let status = subscriptionService.subscriptionStatus {
                                Text("\(status.requestsRemaining) generations remaining this month")
                                    .font(.system(size: 12))
                                    .foregroundColor(.cleanTextSecondary)
                            } else {
                                Text("100 generations per month")
                                    .font(.system(size: 12))
                                    .foregroundColor(.cleanTextSecondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    
                    // Manage subscription button
                    Divider()
                    
                    Button(action: { showingSubscription = true }) {
                        HStack {
                            Text("MANAGE SUBSCRIPTION")
                                .font(.system(size: 12, weight: .medium))
                                .tracking(0.5)
                                .foregroundColor(.cleanTextSecondary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.cleanTextTertiary)
                        }
                        .padding(14)
                    }
                    .buttonStyle(.plain)
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cleanOrange.opacity(0.3), lineWidth: 1)
                )
            } else {
                // Free user - show upgrade card with usage
                Button(action: { showingSubscription = true }) {
                    VStack(spacing: 0) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.cleanBorder, lineWidth: 1)
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: "star")
                                    .font(.system(size: 20))
                                    .foregroundColor(.cleanTextTertiary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("FREE PLAN")
                                    .font(.system(size: 14, weight: .bold))
                                    .tracking(0.5)
                                    .foregroundColor(.cleanTextPrimary)
                                
                                if let status = subscriptionService.subscriptionStatus {
                                    Text("\(status.requestsRemaining)/\(status.requestsLimit) generations remaining")
                                        .font(.system(size: 12))
                                        .foregroundColor(.cleanTextSecondary)
                                } else {
                                    Text("5 generations per month")
                                        .font(.system(size: 12))
                                        .foregroundColor(.cleanTextSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            Text("UPGRADE")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(0.5)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.cleanOrange)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .padding(16)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cleanBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Profile Header (Severance Style)
    
    private var profileHeader: some View {
        VStack(spacing: CleanDesign.spacingL) {
            Text("MY FITO PROFILE")
                .font(.system(size: 12, weight: .semibold))
                .tracking(2)
                .foregroundColor(.cleanTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.top, CleanDesign.spacingL)
            
            // Avatar with profile image
            ZStack(alignment: .bottomTrailing) {
                ProfileAvatarView(
                    profileImagePath: userProfile?.profileImagePath,
                    name: userProfile?.name ?? "F",
                    size: 100
                )
                
            }
            
            // Name with Premium badge
            HStack(spacing: 8) {
                Text((userProfile?.name ?? "Guest User").uppercased())
                    .font(.system(size: 20, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.cleanTextPrimary)
                
                if subscriptionService.hasActiveSubscription {
                    PremiumBadge()
                }
            }
            
            // Email
            Text(currentUser?.email ?? "guest@fito.app")
                .font(.system(size: 13))
                .foregroundColor(.cleanTextSecondary)
            
            // Edit Profile Button
            Button(action: { showingEditProfile = true }) {
                Text("EDIT PROFILE")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(.cleanTextPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.cleanCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.cleanBorder, lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Styling Profile Section
    
    private var stylingProfileSection: some View {
        VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
            Text("STYLING PROFILE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.cleanTextTertiary)
                .tracking(0.5)
                .padding(.leading, CleanDesign.spacingS)
            
            VStack(spacing: 0) {
                ProfileRow(
                    icon: "sparkles",
                    iconColor: .cleanTextSecondary,
                    title: "Style Preferences",
                    subtitle: userProfile?.stylePreferencesText ?? "Tap to set"
                ) {
                    showingStylePreferences = true
                }
                
                Divider().padding(.leading, 56)
                
                ProfileRow(
                    icon: "ruler",
                    iconColor: .cleanTextSecondary,
                    title: "Body Measurements",
                    subtitle: userProfile?.measurementsText ?? "Tap to set"
                ) {
                    showingMeasurements = true
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.cleanBorder, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
            Text("SETTINGS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.cleanTextTertiary)
                .tracking(0.5)
                .padding(.leading, CleanDesign.spacingS)
            
            VStack(spacing: 0) {
                ProfileRow(
                    icon: "bell",
                    iconColor: .cleanTextSecondary,
                    title: "Notifications"
                )
                
                Divider().padding(.leading, 56)
                
                ProfileRow(
                    icon: "lock",
                    iconColor: .cleanTextSecondary,
                    title: "Privacy & Security"
                ) {
                    showingPrivacyPolicy = true
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.cleanBorder, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Data & Privacy Section
    
    private var dataPrivacySection: some View {
        VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
            Text("DATA & PRIVACY")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.cleanTextTertiary)
                .tracking(0.5)
                .padding(.leading, CleanDesign.spacingS)
            
            VStack(spacing: 0) {
                // Export Data
                Button(action: exportUserData) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.cleanBorder, lineWidth: 1)
                                .frame(width: 40, height: 40)
                            
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16))
                                    .foregroundColor(.cleanTextSecondary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export My Data")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.cleanTextPrimary)
                            Text("Download all your data as JSON")
                                .font(.system(size: 12))
                                .foregroundColor(.cleanTextSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.cleanTextTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .disabled(isExporting || !networkMonitor.isConnected)
                .opacity(networkMonitor.isConnected ? 1.0 : 0.5)
                
                Divider().padding(.leading, 56)
                
                // Delete Local Data
                ProfileRow(
                    icon: "trash",
                    iconColor: .cleanTextSecondary,
                    title: "Delete Local Data",
                    subtitle: "Remove clothes & outfits from device"
                ) {
                    showingDeleteAlert = true
                }
                
                Divider().padding(.leading, 56)
                
                // Delete Account
                Button(action: { showingDeleteAccountAlert = true }) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                .frame(width: 40, height: 40)
                            
                            if isDeletingAccount {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "person.crop.circle.badge.minus")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red.opacity(0.7))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Delete Account")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.red.opacity(0.8))
                            Text("Permanently delete your account")
                                .font(.system(size: 12))
                                .foregroundColor(.cleanTextSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.cleanTextTertiary)
                    }
                    .padding(CleanDesign.spacingM)
                }
                .disabled(isDeletingAccount || currentUser?.isGuest == true || !networkMonitor.isConnected)
                .opacity((currentUser?.isGuest == false && networkMonitor.isConnected) ? 1.0 : 0.5)
            }
            .background(Color.cleanCardBg)
            .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusL))
            .shadow(color: .cleanShadow, radius: 8, x: 0, y: 2)
        }
        .alert("Delete Account?", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete My Account", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
        .alert("Export Error", isPresented: $showingExportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportError ?? "Failed to export data")
        }
    }
    
    // MARK: - Export Data
    
    private func exportUserData() {
        guard networkMonitor.isConnected else {
            exportError = "Please connect to the internet to export your data."
            showingExportError = true
            return
        }
        
        guard let token = authService.authToken else {
            exportError = "You must be signed in to export data."
            showingExportError = true
            return
        }
        
        isExporting = true
        HapticFeedback.light()
        
        Task {
            do {
                let exportData = try await FitoBackendService.shared.exportUserData(authToken: token)
                
                await MainActor.run {
                    isExporting = false
                    shareExportedData(exportData)
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = "Failed to export data. Please try again."
                    showingExportError = true
                    HapticFeedback.error()
                }
            }
        }
    }
    
    private func shareExportedData(_ data: Data) {
        // Create temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("fito-data-export-\(Date().timeIntervalSince1970).json")
        
        do {
            try data.write(to: tempURL)
            
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
            
            HapticFeedback.success()
        } catch {
            exportError = "Failed to save export file."
            showingExportError = true
        }
    }
    
    // MARK: - Delete Account
    
    private func deleteAccount() {
        guard networkMonitor.isConnected else { return }
        guard let token = authService.authToken else { return }
        
        isDeletingAccount = true
        HapticFeedback.medium()
        
        Task {
            do {
                try await FitoBackendService.shared.deleteAccount(authToken: token)
                
                await MainActor.run {
                    isDeletingAccount = false
                    
                    // Clear all local data
                    deleteAllData()
                    
                    // Sign out
                    authService.signOut()
                    
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    isDeletingAccount = false
                    exportError = "Failed to delete account. Please try again or contact support."
                    showingExportError = true
                    HapticFeedback.error()
                }
            }
        }
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
            Text("SUPPORT")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.cleanTextTertiary)
                .tracking(0.5)
                .padding(.leading, CleanDesign.spacingS)
            
            VStack(spacing: 0) {
                ProfileRow(
                    icon: "questionmark.circle",
                    iconColor: .cleanTextSecondary,
                    title: "Help Center"
                )
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.cleanBorder, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Logout Button
    
    private var logoutButton: some View {
        Button(action: { showingLogoutAlert = true }) {
            Text("LOG OUT")
                .font(.system(size: 12, weight: .medium))
                .tracking(0.5)
                .foregroundColor(.red.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.cleanBorder, lineWidth: 1)
                )
        }
    }
    
    // MARK: - App Version
    
    private var appVersion: some View {
        Text("Fito v1.0.0")
            .font(.system(size: 12))
            .foregroundColor(.cleanTextTertiary)
            .padding(.top, CleanDesign.spacingS)
    }
    
    // MARK: - Privacy Policy Sheet
    
    private var privacyPolicySheet: some View {
        NavigationStack {
            ZStack {
                CleanBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: CleanDesign.spacingL) {
                        policySection(
                            title: "Data Storage",
                            content: "All your data is stored locally on your device. We do not collect, transmit, or store any of your personal information on external servers."
                        )
                        
                        policySection(
                            title: "Photos",
                            content: "Photos you take or select are saved only on your device in the app's private storage. They are never uploaded or shared."
                        )
                        
                        policySection(
                            title: "AI Processing",
                            content: "When using AI integration, your clothing descriptions (not photos) are sent to generate outfit suggestions. See the privacy policy for details."
                        )
                        
                        policySection(
                            title: "Your Control",
                            content: "You can delete all your data at any time from the Profile settings. This will permanently remove all clothing items and outfit history."
                        )
                    }
                    .padding(CleanDesign.spacingL)
                }
            }
            .navigationTitle("Privacy & Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingPrivacyPolicy = false
                    }
                    .foregroundColor(.cleanOrange)
                }
            }
        }
    }
    
    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.cleanTextPrimary)
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.cleanTextSecondary)
        }
        .padding(CleanDesign.spacingL)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cleanCardBg)
        .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM))
        .shadow(color: .cleanShadow, radius: 6, x: 0, y: 2)
    }
    
    // MARK: - Actions
    
    private func deleteAllData() {
        HapticFeedback.warning()
        for item in clothingItems {
            ImageManager.shared.deleteImage(at: item.imagePath)
            modelContext.delete(item)
        }
        for outfit in outfits {
            modelContext.delete(outfit)
        }
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    let userProfile: UserProfile?
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    
    @State private var name: String = ""
    @State private var gender: String = ""
    @State private var ageRange: String = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var profileImage: UIImage?
    @State private var isSaving = false
    
    private let genderOptions = ["male", "female", "non-binary", "prefer-not-to-say"]
    private let genderDisplayNames = ["Male", "Female", "Non-Binary", "Prefer not to say"]
    private let ageRangeOptions = ["18-24", "25-34", "35-44", "45-54", "55+"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                CleanBackground()
                
                VStack(spacing: CleanDesign.spacingXL) {
                    // Avatar with photo picker
                    ZStack(alignment: .bottomTrailing) {
                        if let image = selectedImage ?? profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.cleanOrange, lineWidth: 3)
                                )
                        } else {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.cleanOrangeLight, Color(white: 0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .overlay {
                                    Text(String(name.prefix(1).uppercased()))
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.cleanOrange)
                                }
                        }
                        
                        // Camera button
                        Button(action: { showingImagePicker = true }) {
                            ZStack {
                                Circle()
                                    .fill(Color.cleanOrange)
                                    .frame(width: 36, height: 36)
                                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                        }
                        .offset(x: 4, y: 4)
                    }
                    .padding(.top, CleanDesign.spacingM)
                    
                    Text("Tap to change photo")
                        .font(.system(size: 13))
                        .foregroundColor(.cleanTextSecondary)
                    
                    // Name Field
                    VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
                        Text("DISPLAY NAME")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1)
                            .foregroundColor(.cleanTextSecondary)
                        
                        TextField("Your name", text: $name)
                            .font(.system(size: 15))
                            .padding(16)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.cleanBorder, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, CleanDesign.spacingL)
                    
                    // Gender Picker
                    VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
                        Text("GENDER")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1)
                            .foregroundColor(.cleanTextSecondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(zip(genderOptions, genderDisplayNames)), id: \.0) { option, displayName in
                                    Button(action: { gender = option }) {
                                        Text(displayName.uppercased())
                                            .font(.system(size: 11, weight: gender == option ? .semibold : .medium))
                                            .tracking(0.5)
                                            .foregroundColor(gender == option ? .white : .cleanTextPrimary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(gender == option ? Color.cleanTextPrimary : Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(gender == option ? Color.clear : Color.cleanBorder, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, CleanDesign.spacingL)
                    
                    // Age Range Picker
                    VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
                        Text("AGE RANGE")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1)
                            .foregroundColor(.cleanTextSecondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(ageRangeOptions, id: \.self) { option in
                                    Button(action: { ageRange = option }) {
                                        Text(option)
                                            .font(.system(size: 11, weight: ageRange == option ? .semibold : .medium))
                                            .foregroundColor(ageRange == option ? .white : .cleanTextPrimary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(ageRange == option ? Color.cleanTextPrimary : Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(ageRange == option ? Color.clear : Color.cleanBorder, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, CleanDesign.spacingL)
                    
                    Spacer()
                    
                    // Save Button
                    Button(action: saveProfile) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isSaving ? "SAVING..." : "SAVE CHANGES")
                                .font(.system(size: 14, weight: .semibold))
                                .tracking(1)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isSaving ? Color.cleanOrange.opacity(0.7) : Color.cleanOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isSaving)
                    .padding(.horizontal, CleanDesign.spacingL)
                    .padding(.bottom, CleanDesign.spacingL)
                }
                .padding(.top, CleanDesign.spacingXL)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("EDIT PROFILE")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(.cleanTextPrimary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 14))
                        .foregroundColor(.cleanTextSecondary)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: .photoLibrary) { image in
                    selectedImage = image
                }
            }
        }
        .onAppear {
            name = userProfile?.name ?? ""
            gender = userProfile?.gender ?? ""
            ageRange = userProfile?.ageRange ?? ""
            loadProfileImage()
        }
    }
    
    private func loadProfileImage() {
        if let path = userProfile?.profileImagePath {
            profileImage = ImageManager.shared.loadImage(from: path)
        }
    }
    
    private func saveProfile() {
        isSaving = true
        
        Task {
            var uploadedImageUrl: String? = nil
            
            // Save to local SwiftData profile
            if let profile = userProfile {
                profile.name = name
                profile.gender = gender.isEmpty ? nil : gender
                profile.ageRange = ageRange.isEmpty ? nil : ageRange
                
                // Save profile image if changed
                if let newImage = selectedImage {
                    let imagePath = ImageManager.shared.saveImage(newImage)
                    if let oldPath = profile.profileImagePath {
                        ImageManager.shared.deleteImage(at: oldPath)
                    }
                    profile.profileImagePath = imagePath
                    
                    // Upload to backend storage
                    if let token = authService.authToken,
                       let imageData = newImage.jpegData(compressionQuality: 0.7) {
                        do {
                            uploadedImageUrl = try await FitoBackendService.shared.uploadProfileImage(
                                imageData: imageData,
                                authToken: token
                            )
                            // Update local path to use backend URL
                            if let url = uploadedImageUrl {
                                profile.profileImagePath = url
                            }
                        } catch {
                            print("Failed to upload profile image: \(error)")
                            // Continue with local path
                        }
                    }
                }
            }
            
            // Sync to backend database
            if let token = authService.authToken {
                do {
                    _ = try await FitoBackendService.shared.updateProfile(
                        name: name.isEmpty ? nil : name,
                        gender: gender.isEmpty ? nil : gender,
                        ageRange: ageRange.isEmpty ? nil : ageRange,
                        profileImage: uploadedImageUrl,
                        authToken: token
                    )
                    
                    // Update AuthService's currentUser
                    if var user = authService.currentUser {
                        user.displayName = name
                        user.gender = gender.isEmpty ? nil : gender
                        user.ageRange = ageRange.isEmpty ? nil : ageRange
                        if let url = uploadedImageUrl {
                            user.avatarURL = url
                        }
                        authService.currentUser = user
                    }
                } catch {
                    print("Failed to sync profile to backend: \(error)")
                }
            }
            
            await MainActor.run {
                isSaving = false
                HapticFeedback.success()
                dismiss()
            }
        }
    }
}

// MARK: - Style Preferences Sheet

struct StylePreferencesSheet: View {
    let userProfile: UserProfile?
    @Environment(\.dismiss) private var dismiss
    
    let styleOptions = ["Minimalist", "Chic", "Bohemian", "Classic", "Streetwear", "Preppy", "Sporty", "Elegant"]
    @State private var selectedStyles: Set<String> = []
    
    private func saveStyles() {
        if let profile = userProfile {
            profile.preferredStyles = Array(selectedStyles)
            HapticFeedback.success()
        }
        dismiss()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                CleanBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: CleanDesign.spacingL) {
                        Text("Select your preferred styles")
                            .font(.system(size: 14))
                            .foregroundColor(.cleanTextSecondary)
                        
                        FlowLayout(spacing: CleanDesign.spacingS) {
                            ForEach(styleOptions, id: \.self) { style in
                                StyleChip(
                                    title: style,
                                    isSelected: selectedStyles.contains(style)
                                ) {
                                    if selectedStyles.contains(style) {
                                        selectedStyles.remove(style)
                                    } else {
                                        selectedStyles.insert(style)
                                    }
                                    HapticFeedback.selection()
                                }
                            }
                        }
                    }
                    .padding(CleanDesign.spacingL)
                }
            }
            .navigationTitle("Style Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveStyles()
                    }
                    .foregroundColor(.cleanOrange)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let profile = userProfile {
                    selectedStyles = Set(profile.preferredStyles)
                }
            }
        }
    }
}

// MARK: - Style Chip

struct StyleChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .cleanTextPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM)
                        .fill(isSelected ? Color.cleanOrange : Color.cleanCardBg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM)
                        .stroke(Color.cleanBorder, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Measurements Sheet

struct MeasurementsSheet: View {
    let userProfile: UserProfile?
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedSize = "Medium"
    @State private var height = ""
    
    let sizes = ["XS", "Small", "Medium", "Large", "XL", "XXL"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                CleanBackground()
                
                VStack(spacing: CleanDesign.spacingXL) {
                    // Size Selection
                    VStack(alignment: .leading, spacing: CleanDesign.spacingM) {
                        Text("Clothing Size")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.cleanTextPrimary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: CleanDesign.spacingS) {
                            ForEach(sizes, id: \.self) { size in
                                Button(action: {
                                    selectedSize = size
                                    HapticFeedback.selection()
                                }) {
                                    Text(size)
                                        .font(.system(size: 14, weight: selectedSize == size ? .semibold : .medium))
                                        .foregroundColor(selectedSize == size ? .white : .cleanTextPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM)
                                                .fill(selectedSize == size ? Color.cleanOrange : Color.cleanCardBg)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM)
                                                .stroke(Color.cleanBorder, lineWidth: selectedSize == size ? 0 : 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Height Field
                    VStack(alignment: .leading, spacing: CleanDesign.spacingS) {
                        Text("Height")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.cleanTextPrimary)
                        
                        TextField("e.g. 5'7\"", text: $height)
                            .font(.system(size: 16))
                            .padding(CleanDesign.spacingL)
                            .background(Color.cleanCardBg)
                            .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusM))
                            .shadow(color: .cleanShadow, radius: 4, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    // Save Button
                    Button(action: saveMeasurements) {
                        Text("Save Measurements")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.cleanOrange)
                            .clipShape(RoundedRectangle(cornerRadius: CleanDesign.cornerRadiusFull))
                    }
                }
                .padding(CleanDesign.spacingL)
            }
            .navigationTitle("Body Measurements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.cleanTextSecondary)
                }
            }
            .onAppear {
                loadExistingMeasurements()
            }
        }
    }
    
    private func loadExistingMeasurements() {
        if let profile = userProfile, let measurements = profile.bodyMeasurements {
            // Parse "Size: Medium, Height: 5'7""
            let parts = measurements.components(separatedBy: ", ")
            for part in parts {
                if part.starts(with: "Size: ") {
                    selectedSize = String(part.dropFirst(6))
                } else if part.starts(with: "Height: ") {
                    height = String(part.dropFirst(8))
                }
            }
        }
    }
    
    private func saveMeasurements() {
        if let profile = userProfile {
            var measurementParts: [String] = []
            measurementParts.append("Size: \(selectedSize)")
            if !height.isEmpty {
                measurementParts.append("Height: \(height)")
            }
            profile.bodyMeasurements = measurementParts.joined(separator: ", ")
            HapticFeedback.success()
        }
        dismiss()
    }
}

// MARK: - Profile Row

struct ProfileRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 14) {
                // Geometric outlined icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.cleanBorder, lineWidth: 1)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.cleanTextSecondary)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.cleanTextPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.cleanTextSecondary)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.cleanTextTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Premium Badge

struct PremiumBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: 8))
            Text("PREMIUM")
                .font(.system(size: 8, weight: .bold))
                .tracking(0.5)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.cleanOrange)
        )
    }
}

// Keep ProBadge for backwards compatibility
struct ProBadge: View {
    var body: some View {
        PremiumBadge()
    }
}

#Preview {
    CleanProfileView()
        .modelContainer(for: [ClothingItem.self, Outfit.self, UserProfile.self], inMemory: true)
}
