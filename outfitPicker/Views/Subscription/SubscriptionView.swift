//
//  SubscriptionView.swift
//  outfitPicker
//
//  Fito - Subscription & Paywall
//  Beautiful paywall with Stripe/StoreKit integration
//

import SwiftUI
import StoreKit

// MARK: - Subscription Tier

enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "FREE"
    case pro = "PRO"
    case premium = "PREMIUM"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .premium: return "Premium"
        }
    }
    
    var monthlyLimit: Int {
        switch self {
        case .free: return 10
        case .pro: return 100
        case .premium: return -1 // Unlimited
        }
    }
    
    var price: String {
        switch self {
        case .free: return "Free"
        case .pro: return "$9.99/mo"
        case .premium: return "$19.99/mo"
        }
    }
    
    var color: Color {
        switch self {
        case .free: return .gray
        case .pro: return .cleanOrange
        case .premium: return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .free: return "person.fill"
        case .pro: return "star.fill"
        case .premium: return "crown.fill"
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "10 outfit generations/month",
                "Basic AI styling",
                "Save up to 50 items"
            ]
        case .pro:
            return [
                "100 outfit generations/month",
                "Advanced AI styling",
                "Unlimited wardrobe",
                "Priority support",
                "Style history"
            ]
        case .premium:
            return [
                "Unlimited generations",
                "Premium AI with trends",
                "Unlimited wardrobe",
                "Priority support",
                "Style reports",
                "Early access features"
            ]
        }
    }
}

// MARK: - Subscription View (Paywall) - Severance Style

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var selectedPlan: SubscriptionTier = .pro
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showMockPurchaseSuccess = false
    @State private var purchasedPlanName = ""
    
    var body: some View {
        ZStack {
            // Severance-style stark background
            Color.cleanBackground
                .ignoresSafeArea()
            
            // Subtle grid overlay
            GeometryReader { geo in
                ForEach(0..<12) { i in
                    Rectangle()
                        .fill(Color.cleanBorder.opacity(0.3))
                        .frame(width: 0.5)
                        .offset(x: CGFloat(i) * (geo.size.width / 11))
                }
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    headerSection
                    
                    // Current usage (if free)
                    if subscriptionService.subscriptionStatus?.tier == "FREE" {
                        currentUsageCard
                    }
                    
                    // Plan cards with buy buttons
                    planCardsSection
                    
                    // Features comparison
                    featuresSection
                    
                    // Restore & Terms
                    footerSection
                }
                .padding()
            }
            
            // Mock purchase success toast
            if showMockPurchaseSuccess {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Successfully subscribed to \(purchasedPlanName)!")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.cleanTextPrimary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.cleanCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .cleanShadow, radius: 10, y: 4)
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") { dismiss() }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.cleanTextSecondary)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            await subscriptionService.loadProducts()
            await subscriptionService.syncSubscriptionWithBackend()
        }
    }
    
    // MARK: - Header (Severance Style)
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Geometric icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.cleanBorder, lineWidth: 1)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .fill(Color.cleanOrange)
                    .frame(width: 56, height: 56)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            Text("UPGRADE YOUR STYLE")
                .font(.system(size: 22, weight: .bold))
                .tracking(2)
                .foregroundColor(.cleanTextPrimary)
            
            Text("Unlock unlimited outfit generations and premium AI styling")
                .font(.system(size: 15))
                .foregroundColor(.cleanTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 24)
    }
    
    // MARK: - Current Usage Card
    
    private var currentUsageCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Usage This Month")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.cleanTextSecondary)
                    
                    let used = subscriptionService.subscriptionStatus?.requestsRemaining ?? 0
                    let limit = subscriptionService.subscriptionStatus?.requestsLimit ?? 10
                    Text("\(limit - used) of \(limit) outfits")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.cleanTextPrimary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.cleanBorder, lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    let used = subscriptionService.subscriptionStatus?.requestsRemaining ?? 0
                    let limit = subscriptionService.subscriptionStatus?.requestsLimit ?? 10
                    let progress = limit > 0 ? Double(limit - used) / Double(limit) : 0.0
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            progress > 0.8 ? Color.red : Color.cleanOrange,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.cleanTextPrimary)
                }
            }
            
            let used = subscriptionService.subscriptionStatus?.requestsRemaining ?? 0
            let limit = subscriptionService.subscriptionStatus?.requestsLimit ?? 10
            let progress = limit > 0 ? Double(limit - used) / Double(limit) : 0.0
            
            if progress > 0.7 {
                Text("⚠️ You're running low on generations!")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.cleanCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .cleanShadow, radius: 8, y: 4)
    }
    
    // MARK: - Plan Cards with Mock Buy Buttons
    
    private var planCardsSection: some View {
        VStack(spacing: 16) {
            // Pro Plan Card
            SeverancePlanCard(
                tier: .pro,
                isSelected: selectedPlan == .pro,
                onSelect: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPlan = .pro
                    }
                },
                onBuy: {
                    mockPurchase(tier: .pro)
                }
            )
            
            // Premium Plan Card
            SeverancePlanCard(
                tier: .premium,
                isSelected: selectedPlan == .premium,
                onSelect: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPlan = .premium
                    }
                },
                onBuy: {
                    mockPurchase(tier: .premium)
                }
            )
        }
    }
    
    private func mockPurchase(tier: SubscriptionTier) {
        HapticFeedback.success()
        purchasedPlanName = tier.displayName
        withAnimation(.spring(response: 0.4)) {
            showMockPurchaseSuccess = true
        }
        
        // Hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.spring(response: 0.4)) {
                showMockPurchaseSuccess = false
            }
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What you'll get")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.cleanTextPrimary)
            
            ForEach(selectedPlan.features, id: \.self) { feature in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.cleanOrange)
                        .font(.system(size: 18))
                    
                    Text(feature)
                        .font(.system(size: 15))
                        .foregroundColor(.cleanTextPrimary)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.cleanCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // Subscribe button removed - using per-card buy buttons instead
    
    // MARK: - Footer
    
    private var footerSection: some View {
        VStack(spacing: 16) {
            Button("Restore Purchases") {
                Task {
                    await subscriptionService.restorePurchases()
                }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.cleanTextSecondary)
            
            Text("Cancel anytime. Subscriptions auto-renew monthly until cancelled.")
                .font(.system(size: 12))
                .foregroundColor(.cleanTextTertiary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                Button("Privacy Policy") {
                    // Open privacy policy
                }
                .font(.system(size: 12))
                .foregroundColor(.cleanTextTertiary)
                
                Button("Terms of Service") {
                    // Open terms
                }
                .font(.system(size: 12))
                .foregroundColor(.cleanTextTertiary)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Subscribe Action
    
    private func subscribe() async {
        isLoading = true
        defer { isLoading = false }
        
        // Find the product for selected plan
        let productId = selectedPlan == .pro ? "com.fito.pro.monthly" : "com.fito.premium.monthly"
        
        guard let product = subscriptionService.products.first(where: { $0.id == productId }) else {
            errorMessage = "Product not available. Please try again later."
            showError = true
            return
        }
        
        do {
            let success = try await subscriptionService.purchase(product)
            if success {
                HapticFeedback.success()
                dismiss()
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Severance Plan Card with Mock Buy Button

struct SeverancePlanCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let onSelect: () -> Void
    let onBuy: () -> Void
    
    @State private var isLoading = false
    
    private var featureItems: [(icon: String, text: String)] {
        switch tier {
        case .pro:
            return [
                ("checkmark", "100 outfit generations per month"),
                ("checkmark", "Advanced AI styling recommendations"),
                ("checkmark", "Unlimited wardrobe items"),
                ("checkmark", "Style history & analytics"),
                ("checkmark", "Priority customer support")
            ]
        case .premium:
            return [
                ("checkmark", "Unlimited outfit generations"),
                ("checkmark", "Premium AI with trend analysis"),
                ("checkmark", "Unlimited wardrobe items"),
                ("checkmark", "Personal style reports"),
                ("checkmark", "Early access to new features"),
                ("checkmark", "Priority customer support")
            ]
        case .free:
            return [
                ("checkmark", "10 outfit generations per month"),
                ("checkmark", "Basic AI styling"),
                ("checkmark", "Save up to 50 items")
            ]
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tap to select
            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: 16) {
                    // Header row
                    HStack {
                        // Plan name
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(tier.displayName.uppercased())
                                    .font(.system(size: 16, weight: .bold))
                                    .tracking(1)
                                    .foregroundColor(.cleanTextPrimary)
                                
                                if tier == .pro {
                                    Text("POPULAR")
                                        .font(.system(size: 9, weight: .bold))
                                        .tracking(0.5)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.cleanTextPrimary)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                            
                            Text(tier == .premium ? "Best for style enthusiasts" : "Great for daily styling")
                                .font(.system(size: 12))
                                .foregroundColor(.cleanTextSecondary)
                        }
                        
                        Spacer()
                        
                        // Price
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(tier.price.replacingOccurrences(of: "/mo", with: ""))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.cleanTextPrimary)
                            
                            Text("per month")
                                .font(.system(size: 11))
                                .foregroundColor(.cleanTextTertiary)
                        }
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(Color.cleanBorder)
                        .frame(height: 1)
                    
                    // Features with clear labels
                    VStack(alignment: .leading, spacing: 10) {
                        Text("INCLUDES")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1)
                            .foregroundColor(.cleanTextTertiary)
                        
                        ForEach(featureItems, id: \.text) { item in
                            HStack(spacing: 10) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.cleanOrange)
                                    .frame(width: 16)
                                
                                Text(item.text)
                                    .font(.system(size: 13))
                                    .foregroundColor(.cleanTextPrimary)
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding(20)
            }
            .buttonStyle(.plain)
            
            // Buy Button
            Button {
                isLoading = true
                HapticFeedback.medium()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isLoading = false
                    onBuy()
                }
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("BUY \(tier.displayName.uppercased())")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(1)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.cleanOrange)
            }
            .disabled(isLoading)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.cleanOrange : Color.cleanBorder, lineWidth: isSelected ? 2 : 1)
        )
    }
}

// MARK: - Usage Limit Alert View

struct UsageLimitView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showSubscription = false
    
    let currentUsage: Int
    let limit: Int
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.orange)
            }
            
            // Title
            Text("Monthly Limit Reached")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.cleanTextPrimary)
            
            // Description
            Text("You've used all \(limit) outfit generations this month. Upgrade to continue styling!")
                .font(.system(size: 16))
                .foregroundColor(.cleanTextSecondary)
                .multilineTextAlignment(.center)
            
            // Usage indicator
            HStack {
                Text("\(currentUsage)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.cleanOrange)
                
                Text("of \(limit) used")
                    .font(.system(size: 16))
                    .foregroundColor(.cleanTextSecondary)
            }
            
            // Upgrade button
            Button {
                showSubscription = true
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Upgrade Now")
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.cleanOrange)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            // Wait option
            Button {
                dismiss()
            } label: {
                Text("Wait until next month")
                    .font(.system(size: 15))
                    .foregroundColor(.cleanTextSecondary)
            }
        }
        .padding(32)
        .background(Color.cleanBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .padding(24)
        .sheet(isPresented: $showSubscription) {
            NavigationStack {
                SubscriptionView()
            }
        }
    }
}

// MARK: - Subscription Badge (for profile)

struct SubscriptionBadge: View {
    let tier: SubscriptionTier
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: tier.icon)
                .font(.system(size: 12, weight: .bold))
            
            Text(tier.displayName)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: [tier.color, tier.color.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SubscriptionView()
    }
}
