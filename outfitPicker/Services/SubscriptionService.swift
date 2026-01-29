//
//  SubscriptionService.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  In-App Purchase & Subscription Management
//

import Foundation
import StoreKit

// MARK: - Subscription Service

@MainActor
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    // MARK: - Published Properties
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var subscriptionStatus: SubscriptionStatus?
    @Published var isLoading = false
    @Published var error: SubscriptionError?
    
    // MARK: - Product IDs (Configure in App Store Connect)
    
    enum ProductID {
        static let premiumMonthly = "com.fito.premium.monthly"
        static let premiumYearly = "com.fito.premium.yearly"
        static let proMonthly = "com.fito.pro.monthly"
        static let proYearly = "com.fito.pro.yearly"
        
        static let all = [premiumMonthly, premiumYearly, proMonthly, proYearly]
    }
    
    // MARK: - Computed Properties
    
    /// Check if user has premium via StoreKit OR backend database
    var isPremium: Bool {
        // Check StoreKit purchases
        if purchasedProductIDs.contains(ProductID.premiumMonthly) ||
           purchasedProductIDs.contains(ProductID.premiumYearly) {
            return true
        }
        // Check backend subscription status
        if let status = subscriptionStatus, status.tier == "PREMIUM" && status.isActive {
            return true
        }
        return isPro
    }
    
    var isPro: Bool {
        purchasedProductIDs.contains(ProductID.proMonthly) ||
        purchasedProductIDs.contains(ProductID.proYearly)
    }
    
    /// Main check: user has active subscription from any source
    var hasActiveSubscription: Bool {
        // Check StoreKit
        if isPremium || isPro {
            return true
        }
        // Check backend subscription
        if let status = subscriptionStatus, status.tier == "PREMIUM" && status.isActive {
            return true
        }
        return false
    }
    
    var currentTier: SubscriptionTier {
        if isPro { return .pro }
        if isPremium { return .premium }
        if let status = subscriptionStatus, status.tier == "PREMIUM" && status.isActive {
            return .premium
        }
        return .free
    }
    
    var canGenerateOutfit: Bool {
        guard let status = subscriptionStatus else { return true } // Allow if not loaded
        return status.requestsRemaining > 0 || hasActiveSubscription
    }
    
    // MARK: - Initialization
    
    private init() {
        Task {
            await loadProducts()
            await updatePurchasedProducts()
            await listenForTransactions()
            // Also sync with backend to get database subscription status
            await syncSubscriptionWithBackend()
        }
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            products = try await Product.products(for: ProductID.all)
            products.sort { $0.price < $1.price }
        } catch {
            self.error = .productLoadFailed
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            
            // Sync with backend
            await syncSubscriptionWithBackend()
            
            return true
            
        case .userCancelled:
            return false
            
        case .pending:
            return false
            
        @unknown default:
            return false
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            await syncSubscriptionWithBackend()
        } catch {
            self.error = .restoreFailed
        }
    }
    
    // MARK: - Update Purchased Products
    
    func updatePurchasedProducts() async {
        var purchasedIDs: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            if transaction.revocationDate == nil {
                purchasedIDs.insert(transaction.productID)
            }
        }
        
        purchasedProductIDs = purchasedIDs
    }
    
    // MARK: - Listen for Transactions
    
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            await updatePurchasedProducts()
            await transaction.finish()
        }
    }
    
    // MARK: - Sync with Backend
    
    func syncSubscriptionWithBackend() async {
        guard let user = AuthService.shared.currentUser,
              let token = AuthService.shared.authToken else { return }
        
        do {
            subscriptionStatus = try await FitoBackendService.shared.checkSubscription(
                userId: user.id,
                authToken: token
            )
        } catch {
            print("Failed to sync subscription: \(error)")
        }
    }
    
    // MARK: - Check Usage
    
    func trackOutfitGeneration() async {
        guard let user = AuthService.shared.currentUser,
              let token = AuthService.shared.authToken else { return }
        
        do {
            try await FitoBackendService.shared.trackUsage(
                userId: user.id,
                authToken: token,
                action: .generateOutfit
            )
            // Refresh status
            await syncSubscriptionWithBackend()
        } catch {
            print("Failed to track usage: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Subscription Error

enum SubscriptionError: LocalizedError {
    case productLoadFailed
    case purchaseFailed
    case verificationFailed
    case restoreFailed
    
    var errorDescription: String? {
        switch self {
        case .productLoadFailed:
            return "Failed to load subscription options"
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        case .verificationFailed:
            return "Could not verify purchase"
        case .restoreFailed:
            return "Could not restore purchases"
        }
    }
}

// MARK: - Subscription Plans View

import SwiftUI

struct SubscriptionPlansView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Severance-style background
                Color.cleanBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Features Comparison
                        featuresSection
                        
                        // Plans
                        plansSection
                        
                        // Restore Button
                        restoreButton
                        
                        // Terms
                        termsSection
                    }
                    .padding(20)
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("UPGRADE")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(.cleanTextPrimary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 14))
                        .foregroundColor(.cleanTextSecondary)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("UNLOCK PREMIUM")
                .font(.system(size: 22, weight: .bold))
                .tracking(2)
                .foregroundColor(.cleanTextPrimary)
            
            Text("Get more AI outfit generations and exclusive features")
                .font(.system(size: 14))
                .foregroundColor(.cleanTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Features
    
    private var featuresSection: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Text("FEATURE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(.cleanTextTertiary)
                
                Spacer()
                
                HStack(spacing: 24) {
                    Text("FREE")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(.cleanTextTertiary)
                        .frame(width: 40)
                    
                    Text("PREMIUM")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                        .foregroundColor(.cleanOrange)
                        .frame(width: 60)
                }
            }
            .padding()
            .background(Color.cleanBackground)
            
            Rectangle()
                .fill(Color.cleanBorder)
                .frame(height: 1)
            
            // Feature rows
            featureRow(icon: "sparkles", text: "Generations", free: "5/Mo", premium: "100/Mo")
            featureRow(icon: "wand.and.stars", text: "Style Analysis", free: "Basic", premium: "Advanced")
            featureRow(icon: "heart.fill", text: "Save Outfits", free: "3", premium: "Unlimited")
            featureRow(icon: "tshirt", text: "Closet Items", free: "20", premium: "Unlimited")
            featureRow(icon: "bell.fill", text: "Early Access to Features", free: "—", premium: "✓")
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cleanBorder, lineWidth: 1)
        )
    }
    
    private func featureRow(icon: String, text: String, free: String, premium: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.cleanBorder, lineWidth: 1)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: icon)
                            .font(.system(size: 12))
                            .foregroundColor(.cleanTextSecondary)
                    }
                    
                    Text(text)
                        .font(.system(size: 13))
                        .foregroundColor(.cleanTextPrimary)
                }
                
                Spacer()
                
                HStack(spacing: 24) {
                    Text(free)
                        .font(.system(size: 12))
                        .foregroundColor(.cleanTextSecondary)
                        .frame(width: 40)
                    
                    Text(premium)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.cleanOrange)
                        .frame(width: 60)
                }
            }
            .padding()
            
            Rectangle()
                .fill(Color.cleanBorder)
                .frame(height: 1)
        }
    }
    
    // MARK: - Plans
    
    private var plansSection: some View {
        VStack(spacing: 16) {
            // If real products exist, show them
            if !subscriptionService.products.isEmpty {
                ForEach(subscriptionService.products) { product in
                    PlanCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        isPurchasing: isPurchasing
                    ) {
                        selectedProduct = product
                        purchaseProduct(product)
                    }
                }
            } else {
                // Show mock plan cards for development/preview
                MockPlanCard(
                    name: "MONTHLY",
                    price: "$9.99",
                    period: "per month",
                    description: "Perfect for trying premium",
                    onBuy: {
                        HapticFeedback.success()
                        dismiss()
                    }
                )
                
                MockPlanCard(
                    name: "YEARLY",
                    price: "$49.99",
                    period: "per year",
                    description: "Best value - save more than50%",
                    isBestValue: true,
                    onBuy: {
                        HapticFeedback.success()
                        dismiss()
                    }
                )
            }
        }
    }
    
    // MARK: - Restore
    
    private var restoreButton: some View {
        Button {
            Task {
                await subscriptionService.restorePurchases()
            }
        } label: {
            Text("Restore Purchases")
                .font(.system(size: 15))
                .foregroundColor(.cleanOrange)
        }
    }
    
    // MARK: - Terms
    
    private var termsSection: some View {
        VStack(spacing: CleanDesign.spacingXS) {
            Text("Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period.")
                .font(.system(size: 11))
                .foregroundColor(.cleanTextTertiary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: CleanDesign.spacingM) {
                Link("Terms of Use", destination: URL(string: "https://yourapp.com/terms")!)
                Text("•")
                Link("Privacy Policy", destination: URL(string: "https://yourapp.com/privacy")!)
            }
            .font(.system(size: 11))
            .foregroundColor(.cleanOrange)
        }
        .padding(.top, CleanDesign.spacingL)
    }
    
    // MARK: - Purchase
    
    private func purchaseProduct(_ product: Product) {
        isPurchasing = true
        
        Task {
            do {
                let success = try await subscriptionService.purchase(product)
                if success {
                    HapticFeedback.success()
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
                HapticFeedback.error()
            }
            isPurchasing = false
        }
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let product: Product
    let isSelected: Bool
    let isPurchasing: Bool
    let onTap: () -> Void
    
    private var isYearly: Bool {
        product.id.contains("yearly")
    }
    
    private var savings: String? {
        if isYearly {
            return "SAVE 40%"
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Product info
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(product.displayName.uppercased())
                                .font(.system(size: 16, weight: .bold))
                                .tracking(1)
                                .foregroundColor(.cleanTextPrimary)
                            
                            if let savings = savings {
                                Text(savings)
                                    .font(.system(size: 9, weight: .bold))
                                    .tracking(0.5)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.cleanTextPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        
                        Text(isYearly ? "Best value for regular users" : "Perfect for trying premium")
                            .font(.system(size: 12))
                            .foregroundColor(.cleanTextSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(product.displayPrice)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.cleanTextPrimary)
                        
                        Text(isYearly ? "per year" : "per month")
                            .font(.system(size: 11))
                            .foregroundColor(.cleanTextTertiary)
                    }
                }
            }
            .padding(16)
            
            // Buy Button
            Button(action: onTap) {
                HStack(spacing: 8) {
                    if isPurchasing && isSelected {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("BUY \(product.displayName.uppercased())")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(1)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.cleanOrange)
            }
            .disabled(isPurchasing)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.cleanOrange : Color.cleanBorder, lineWidth: isSelected ? 2 : 1)
        )
    }
}

// MARK: - Mock Plan Card (for development/testing)

struct MockPlanCard: View {
    let name: String
    let price: String
    let period: String
    let description: String
    var isBestValue: Bool = false
    let onBuy: () -> Void
    
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Product info
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(name)
                                .font(.system(size: 16, weight: .bold))
                                .tracking(1)
                                .foregroundColor(.cleanTextPrimary)
                            
                            if isBestValue {
                                Text("BEST VALUE")
                                    .font(.system(size: 9, weight: .bold))
                                    .tracking(0.5)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.cleanTextPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundColor(.cleanTextSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(price)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.cleanTextPrimary)
                        
                        Text(period)
                            .font(.system(size: 11))
                            .foregroundColor(.cleanTextTertiary)
                    }
                }
            }
            .padding(16)
            
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
                        Text("BUY \(name)")
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
                .stroke(Color.cleanBorder, lineWidth: 1)
        )
    }
}

#Preview {
    SubscriptionPlansView()
}
