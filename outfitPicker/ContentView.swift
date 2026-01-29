//
//  ContentView.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @StateObject private var authService = AuthService.shared
    @State private var showProfileSetup = false
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
                    .onAppear {
                        ensureUserProfileExists()
                        syncAuthUserToProfile()
                        syncSubscriptionStatus()
                        checkProfileSetup()
                    }
                    .fullScreenCover(isPresented: $showProfileSetup) {
                        ProfileSetupView(authService: authService)
                    }
            } else {
                CleanOnboardingView(authService: authService)
            }
        }
        .animation(.spring(response: 0.5), value: authService.isAuthenticated)
        .onChange(of: authService.currentUser?.profileCompleted) { _, newValue in
            // Hide profile setup when completed
            if newValue == true {
                showProfileSetup = false
            }
        }
    }
    
    private func ensureUserProfileExists() {
        if userProfiles.isEmpty {
            let name = authService.currentUser?.displayName ?? "Stylist"
            let newProfile = UserProfile(name: name)
            modelContext.insert(newProfile)
        }
    }
    
    private func syncAuthUserToProfile() {
        // First, try to fetch fresh profile data from backend
        Task {
            await fetchAndSyncProfileFromBackend()
        }
        
        // Then sync what we have locally
        if let user = authService.currentUser,
           let profile = userProfiles.first {
            // Sync name
            if profile.name != user.displayName {
                profile.name = user.displayName
            }
            // Sync gender and age range from backend
            if let gender = user.gender {
                profile.gender = gender
            }
            if let ageRange = user.ageRange {
                profile.ageRange = ageRange
            }
        }
    }
    
    private func fetchAndSyncProfileFromBackend() async {
        guard let token = authService.authToken else { return }
        
        do {
            let profile = try await FitoBackendService.shared.getProfile(authToken: token)
            
            await MainActor.run {
                // Update AuthService's currentUser
                if var user = authService.currentUser {
                    user.gender = profile.gender
                    user.ageRange = profile.ageRange
                    user.profileCompleted = profile.profileCompleted
                    if let name = profile.name, !name.isEmpty {
                        user.displayName = name
                    }
                    authService.currentUser = user
                }
                
                // Update local UserProfile
                if let localProfile = userProfiles.first {
                    if let gender = profile.gender {
                        localProfile.gender = gender
                    }
                    if let ageRange = profile.ageRange {
                        localProfile.ageRange = ageRange
                    }
                    if let name = profile.name, !name.isEmpty {
                        localProfile.name = name
                    }
                }
            }
        } catch {
            print("Failed to fetch profile from backend: \(error)")
        }
    }
    
    private func syncSubscriptionStatus() {
        Task {
            await SubscriptionService.shared.syncSubscriptionWithBackend()
        }
    }
    
    private func checkProfileSetup() {
        // Show profile setup for new users who haven't completed it
        if let user = authService.currentUser,
           user.needsProfileSetup {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showProfileSetup = true
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case tryOn = "Try-On"
        case closet = "Closet"
        case history = "Saved"
        case profile = "Profile"
        
        var icon: String {
            switch self {
            case .home: return "house"
            case .tryOn: return "person.and.background.dotted"
            case .closet: return "hanger"
            case .history: return "heart"
            case .profile: return "person"
            }
        }
        
        var selectedIcon: String {
            switch self {
            case .home: return "house.fill"
            case .tryOn: return "person.and.background.dotted"
            case .closet: return "hanger"
            case .history: return "heart.fill"
            case .profile: return "person.fill"
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Content Views
                Group {
                    switch selectedTab {
                    case .home:
                        CleanHomeView()
                    case .tryOn:
                        VirtualTryOnView()
                    case .closet:
                        CleanClosetView()
                    case .history:
                        CleanHistoryView()
                    case .profile:
                        CleanProfileView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 60) // Space for tab bar content
                }
                
                // Tab Bar
                CleanTabBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Clean Tab Bar (Severance Style)

struct CleanTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    var body: some View {
        VStack(spacing: 0) {
            // Top border - crisp line
            Rectangle()
                .fill(Color.cleanBorder)
                .frame(height: 1)
            
            // Tab items
            HStack(spacing: 0) {
                ForEach(MainTabView.Tab.allCases, id: \.self) { tab in
                    TabBarItem(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                        HapticFeedback.light()
                    }
                }
            }
            .padding(.top, 14)
            .padding(.bottom, 10)
            
            // Bottom safe area fill
            Color.white
                .frame(height: max(safeAreaInsets.bottom, 0))
        }
        .background(Color.white)
    }
}

// MARK: - Safe Area Insets Environment Key

private struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .windows.first?.safeAreaInsets.toEdgeInsets ?? EdgeInsets()
    }
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}

extension UIEdgeInsets {
    var toEdgeInsets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

// MARK: - Tab Bar Item (Severance Style)

struct TabBarItem: View {
    let tab: MainTabView.Tab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Icon with selection indicator
                ZStack {
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 22, weight: isSelected ? .medium : .regular))
                        .symbolRenderingMode(.monochrome)
                }
                
                // Label with tracking
                Text(tab.rawValue.uppercased())
                    .font(.system(size: 9, weight: .medium))
                    .tracking(0.5)
            }
            .foregroundColor(isSelected ? .cleanOrange : .cleanTextTertiary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ClothingItem.self, Outfit.self, UserProfile.self], inMemory: true)
}

