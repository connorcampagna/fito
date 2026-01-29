//
//  FitoProComponents.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  Fito Premium Upsell Components - Severance Style
//

import SwiftUI

// MARK: - Usage Limit Banner

struct UsageLimitBanner: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showSubscriptionView = false
    
    private var usedCount: Int {
        subscriptionService.subscriptionStatus?.requestsRemaining ?? 0
    }
    
    private var limitCount: Int {
        subscriptionService.subscriptionStatus?.requestsLimit ?? 10
    }
    
    private var remaining: Int {
        max(0, limitCount - usedCount)
    }
    
    private var shouldShow: Bool {
        !subscriptionService.hasActiveSubscription
    }
    
    var body: some View {
        if shouldShow {
            Button(action: { showSubscriptionView = true }) {
                HStack(spacing: 14) {
                    // Geometric progress indicator
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.cleanBorder, lineWidth: 1)
                            .frame(width: 44, height: 44)
                        
                        Text("\(remaining)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(remaining > 3 ? .cleanOrange : .red)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(remaining) OUTFITS LEFT")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(0.5)
                            .foregroundColor(.cleanTextPrimary)
                        
                        Text("Upgrade for unlimited styling")
                            .font(.system(size: 11))
                            .foregroundColor(.cleanTextSecondary)
                    }
                    
                    Spacer()
                    
                    Text("PREMIUM")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.cleanOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cleanBorder, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showSubscriptionView) {
                SubscriptionPlansView()
            }
        }
    }
}

// MARK: - Inline Premium Upsell (Small)

struct InlineProUpsell: View {
    let message: String
    @State private var showSubscriptionView = false
    
    var body: some View {
        Button(action: { showSubscriptionView = true }) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.cleanOrange, lineWidth: 1)
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(.cleanOrange)
                }
                
                Text(message.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.5)
                    .foregroundColor(.cleanTextPrimary)
                
                Spacer()
                
                Text("UPGRADE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(.cleanOrange)
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.cleanBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSubscriptionView) {
            SubscriptionPlansView()
        }
    }
}

// MARK: - Feature Lock Overlay

struct FeatureLockOverlay: View {
    let feature: String
    @State private var showSubscriptionView = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Geometric lock icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.cleanBorder, lineWidth: 1)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.cleanOrange)
            }
            
            VStack(spacing: 8) {
                Text("PREMIUM FEATURE")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.cleanTextPrimary)
                
                Text(feature)
                    .font(.system(size: 13))
                    .foregroundColor(.cleanTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showSubscriptionView = true }) {
                Text("UNLOCK WITH PREMIUM")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.cleanOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 32)
        }
        .padding(32)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cleanBorder, lineWidth: 1)
        )
        .sheet(isPresented: $showSubscriptionView) {
            SubscriptionPlansView()
        }
    }
}

// MARK: - Subscription Tier Indicator

struct SubscriptionTierIndicator: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    private var tierName: String {
        subscriptionService.currentTier.displayName.uppercased()
    }
    
    var body: some View {
        HStack(spacing: 6) {
            if subscriptionService.hasActiveSubscription {
                Image(systemName: "crown.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
            }
            
            Text(tierName)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(subscriptionService.hasActiveSubscription ? .white : .cleanTextSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(subscriptionService.hasActiveSubscription ? Color.cleanOrange : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(subscriptionService.hasActiveSubscription ? Color.clear : Color.cleanBorder, lineWidth: 1)
        )
    }
}

// MARK: - Fito Premium Upsell Card

struct FitoProUpsellCard: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showSubscriptionView = false
    
    private var shouldShow: Bool {
        !subscriptionService.hasActiveSubscription
    }
    
    var body: some View {
        if shouldShow {
            Button(action: { showSubscriptionView = true }) {
                VStack(spacing: 16) {
                    HStack(spacing: 14) {
                        // Geometric icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.cleanOrange, lineWidth: 1)
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.cleanOrange)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FITO PREMIUM")
                                .font(.system(size: 14, weight: .bold))
                                .tracking(1)
                                .foregroundColor(.cleanTextPrimary)
                            
                            Text("Unlimited outfits • Premium styles")
                                .font(.system(size: 12))
                                .foregroundColor(.cleanTextSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.cleanTextTertiary)
                    }
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cleanOrange.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showSubscriptionView) {
                SubscriptionPlansView()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        UsageLimitBanner()
        InlineProUpsell(message: "Unlock unlimited outfit saves")
        SubscriptionTierIndicator()
        FitoProUpsellCard()
    }
    .padding()
    .background(Color.cleanBackground)
}
