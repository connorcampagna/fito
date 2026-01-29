//
//  ProfileSetupView.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  Beautiful Profile Setup Onboarding
//

import SwiftUI

struct ProfileSetupView: View {
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var selectedGender: String = ""
    @State private var selectedAgeRange: String = ""
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let genderOptions = [
        ("male", "Male", "figure.stand"),
        ("female", "Female", "figure.stand.dress"),
        ("non-binary", "Non-Binary", "figure.2"),
        ("prefer-not-to-say", "Prefer not to say", "person.fill.questionmark")
    ]
    
    private let ageRanges = ["18-24", "25-34", "35-44", "45-54", "55+"]
    
    var body: some View {
        ZStack {
            // Animated gradient background
            ProfileSetupBackground()
            
            VStack(spacing: 0) {
                // Progress bar
                progressBar
                    .padding(.top, 20)
                    .padding(.horizontal, 32)
                
                // Content
                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    genderStep.tag(1)
                    ageStep.tag(2)
                    photoStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                
                // Navigation buttons
                navigationButtons
                    .padding(.horizontal, 28)
                    .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: .photoLibrary) { image in
                profileImage = image
            }
        }
        .alert("Oops!", isPresented: $showError) {
            Button("Try Again", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(0..<4) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.cleanOrange : Color.cleanBorder)
                    .frame(height: 4)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
    }
    
    // MARK: - Welcome Step
    
    private var welcomeStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Geometric icon
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.cleanBorder, lineWidth: 1)
                    .frame(width: 120, height: 120)
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cleanOrange)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 16) {
                Text("LET'S PERSONALIZE\nYOUR STYLE")
                    .font(.system(size: 24, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.cleanTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text("A few quick questions to help our AI\nstyle you perfectly")
                    .font(.system(size: 14))
                    .foregroundColor(.cleanTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Premium teaser
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.cleanOrange, lineWidth: 1)
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.cleanOrange)
                }
                
                Text("UNLOCK UNLIMITED OUTFITS WITH PREMIUM")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(0.5)
                    .foregroundColor(.cleanTextPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.cleanBorder, lineWidth: 1)
            )
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Gender Step
    
    private var genderStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("How do you identify?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.cleanTextPrimary)
                
                Text("This helps us suggest the right styles for you")
                    .font(.system(size: 16))
                    .foregroundColor(.cleanTextSecondary)
            }
            
            // Gender options
            VStack(spacing: 14) {
                ForEach(genderOptions, id: \.0) { option in
                    GenderOptionButton(
                        id: option.0,
                        label: option.1,
                        icon: option.2,
                        isSelected: selectedGender == option.0
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedGender = option.0
                        }
                        HapticFeedback.selection()
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Age Step
    
    private var ageStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("What's your age range?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.cleanTextPrimary)
                
                Text("We'll tailor outfit suggestions to your lifestyle")
                    .font(.system(size: 16))
                    .foregroundColor(.cleanTextSecondary)
            }
            
            // Age range options - horizontal layout
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(ageRanges, id: \.self) { range in
                    AgeRangeButton(
                        range: range,
                        isSelected: selectedAgeRange == range
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedAgeRange = range
                        }
                        HapticFeedback.selection()
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Photo Step
    
    private var photoStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("Add a profile photo")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.cleanTextPrimary)
                
                Text("Optional, but it makes your profile pop!")
                    .font(.system(size: 16))
                    .foregroundColor(.cleanTextSecondary)
            }
            
            // Profile photo picker
            Button(action: { showingImagePicker = true }) {
                ZStack {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 160, height: 160)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.cleanOrange, lineWidth: 4)
                            )
                            .shadow(color: Color.cleanOrange.opacity(0.4), radius: 16, y: 8)
                    } else {
                        Circle()
                            .fill(Color.cleanCardBg)
                            .frame(width: 160, height: 160)
                            .overlay(
                                Circle()
                                    .stroke(Color.cleanBorder, style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                            )
                            .overlay {
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.cleanTextTertiary)
                                    
                                    Text("Add Photo")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.cleanTextTertiary)
                                }
                            }
                            .shadow(color: .cleanShadow, radius: 8, x: 0, y: 4)
                    }
                    
                    // Edit button
                    if profileImage != nil {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(Color.cleanOrange)
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                            }
                        }
                        .frame(width: 160, height: 160)
                    }
                }
            }
            
            // Skip text
            if profileImage == nil {
                Text("You can always add this later")
                    .font(.system(size: 14))
                    .foregroundColor(.cleanTextTertiary)
            }
            
            Spacer()
            
            // Fito Pro banner
            FitoProBanner()
                .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Back button (not on first step)
            if currentStep > 0 {
                Button {
                    withAnimation {
                        currentStep -= 1
                    }
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.cleanTextPrimary)
                        .frame(width: 56, height: 56)
                        .background(Color.cleanCardBg)
                        .clipShape(Circle())
                        .shadow(color: .cleanShadow, radius: 6, x: 0, y: 3)
                }
            }
            
            // Next/Complete button
            Button {
                handleNextTap()
            } label: {
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(currentStep == 3 ? "Let's Go!" : "Continue")
                            .font(.system(size: 17, weight: .bold))
                        
                        Image(systemName: currentStep == 3 ? "sparkles" : "arrow.right")
                            .font(.system(size: 15, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: canProceed ? [Color.cleanOrange, Color.cleanOrange.opacity(0.85)] : [Color.gray, Color.gray.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: canProceed ? Color.cleanOrange.opacity(0.4) : .clear, radius: 12, y: 6)
            }
            .disabled(!canProceed || isLoading)
        }
    }
    
    // MARK: - Helpers
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !selectedGender.isEmpty
        case 2: return !selectedAgeRange.isEmpty
        case 3: return true // Photo is optional
        default: return false
        }
    }
    
    private func handleNextTap() {
        if currentStep < 3 {
            withAnimation(.spring(response: 0.4)) {
                currentStep += 1
            }
            HapticFeedback.light()
        } else {
            completeSetup()
        }
    }
    
    private func completeSetup() {
        isLoading = true
        
        Task {
            do {
                let imageData = profileImage?.jpegData(compressionQuality: 0.7)
                
                try await authService.completeProfileSetup(
                    name: authService.currentUser?.displayName,
                    gender: selectedGender,
                    ageRange: selectedAgeRange,
                    profileImageData: imageData
                )
                
                await MainActor.run {
                    isLoading = false
                    HapticFeedback.success()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to save profile. Please try again."
                    showError = true
                    HapticFeedback.error()
                }
            }
        }
    }
}

// MARK: - Gender Option Button

struct GenderOptionButton: View {
    let id: String
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .cleanOrange : .cleanTextSecondary)
                    .frame(width: 32)
                
                Text(label)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(isSelected ? .cleanTextPrimary : .cleanTextSecondary)
                
                Spacer()
                
                Circle()
                    .stroke(isSelected ? Color.cleanOrange : Color.cleanBorder, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay {
                        if isSelected {
                            Circle()
                                .fill(Color.cleanOrange)
                                .frame(width: 14, height: 14)
                        }
                    }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.cleanOrangeLight : Color.cleanCardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.cleanOrange : Color.cleanBorder, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: .cleanShadow, radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Age Range Button

struct AgeRangeButton: View {
    let range: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(range)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isSelected ? .white : .cleanTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.cleanOrange : Color.cleanCardBg)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.cleanOrange : Color.cleanBorder, lineWidth: isSelected ? 0 : 1)
                )
                .shadow(color: isSelected ? Color.cleanOrange.opacity(0.4) : .cleanShadow, radius: isSelected ? 8 : 4, y: isSelected ? 4 : 2)
        }
    }
}

// MARK: - Profile Setup Gradient Background

struct ProfileSetupBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.cleanBackground,
                Color.cleanOrangeLight.opacity(0.3),
                Color.cleanBackground
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .overlay {
            // Gradient orbs
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(Color.cleanOrange.opacity(0.12))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(
                            x: animateGradient ? geometry.size.width * 0.3 : -geometry.size.width * 0.2,
                            y: animateGradient ? -geometry.size.height * 0.1 : geometry.size.height * 0.2
                        )
                    
                    Circle()
                        .fill(Color.cleanOrange.opacity(0.08))
                        .frame(width: 250, height: 250)
                        .blur(radius: 50)
                        .offset(
                            x: animateGradient ? -geometry.size.width * 0.3 : geometry.size.width * 0.2,
                            y: animateGradient ? geometry.size.height * 0.3 : -geometry.size.height * 0.1
                        )
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Fito Premium Banner

struct FitoProBanner: View {
    var body: some View {
        HStack(spacing: 14) {
            // Geometric crown icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.cleanOrange, lineWidth: 1)
                    .frame(width: 48, height: 48)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.cleanOrange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("UPGRADE TO PREMIUM")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(.cleanTextPrimary)
                
                Text("Unlimited outfits • Premium styles • No ads")
                    .font(.system(size: 11))
                    .foregroundColor(.cleanTextSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.cleanTextTertiary)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cleanOrange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    ProfileSetupView(authService: AuthService.shared)
}
