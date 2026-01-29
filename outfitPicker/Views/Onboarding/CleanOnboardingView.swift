//
//  CleanOnboardingView.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  Severance-Inspired Onboarding Experience
//

import SwiftUI

// MARK: - Main Onboarding View

struct CleanOnboardingView: View {
    @ObservedObject var authService: AuthService
    @State private var currentPage = 0
    @State private var showAuthSheet = false
    @State private var animateGrid = false
    
    var body: some View {
        ZStack {
            // Severance-style stark white background with subtle grid
            SeveranceBackground(animate: $animateGrid)
            
            VStack(spacing: 0) {
                // Page Content
                TabView(selection: $currentPage) {
                    SeveranceOnboardingSlide(
                        icon: "tshirt.fill",
                        title: "Your Digital Closet",
                        subtitle: "Snap photos of your clothes and build your personal wardrobe in seconds",
                        pageIndex: 0
                    )
                    .tag(0)
                    
                    SeveranceOnboardingSlide(
                        icon: "wand.and.stars",
                        title: "AI Stylist",
                        subtitle: "Tell Fito your occasion and get the perfect outfit recommendation instantly",
                        pageIndex: 1
                    )
                    .tag(1)
                    
                    SeveranceOnboardingSlide(
                        icon: "heart.fill",
                        title: "Save Favorites",
                        subtitle: "Build your style history and never forget your best looks",
                        pageIndex: 2
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Minimal Page Indicator
                HStack(spacing: 12) {
                    ForEach(0..<3) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(currentPage == index ? Color.cleanOrange : Color.cleanBorder)
                            .frame(width: currentPage == index ? 24 : 8, height: 4)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
                    }
                }
                .padding(.top, 32)
                
                Spacer()
                
                // Get Started Button - Clean, minimal
                Button {
                    showAuthSheet = true
                } label: {
                    Text("Get Started")
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .tracking(0.5)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.cleanOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 56)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                animateGrid = true
            }
        }
        .fullScreenCover(isPresented: $showAuthSheet) {
            SeveranceAuthView(authService: authService)
        }
    }
}

// MARK: - Severance Background

struct SeveranceBackground: View {
    @Binding var animate: Bool
    
    var body: some View {
        ZStack {
            // Base stark white
            Color.cleanBackground
                .ignoresSafeArea()
            
            // Subtle animated grid lines
            GeometryReader { geo in
                // Vertical lines
                ForEach(0..<12) { i in
                    Rectangle()
                        .fill(Color.cleanBorder.opacity(0.4))
                        .frame(width: 0.5)
                        .offset(x: CGFloat(i) * (geo.size.width / 11))
                }
                
                // Horizontal lines
                ForEach(0..<20) { i in
                    Rectangle()
                        .fill(Color.cleanBorder.opacity(0.3))
                        .frame(height: 0.5)
                        .offset(y: CGFloat(i) * (geo.size.height / 19))
                }
                
                // Animated accent line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.cleanOrange.opacity(0.15), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .offset(y: animate ? geo.size.height : 0)
            }
        }
    }
}

// MARK: - Severance Onboarding Slide

struct SeveranceOnboardingSlide: View {
    let icon: String
    let title: String
    let subtitle: String
    let pageIndex: Int
    
    @State private var isAnimating = false
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 48) {
            Spacer()
            
            // Geometric Icon Container (Severance style)
            ZStack {
                // Outer rotating square
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.cleanBorder, lineWidth: 1)
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(isAnimating ? 45 : 0))
                    .opacity(0.6)
                
                // Middle static square
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.cleanOrange.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 130, height: 130)
                
                // Inner circle with icon
                Circle()
                    .fill(Color.cleanOrange)
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.cleanOrange.opacity(0.3), radius: 20, x: 0, y: 10)
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            
            // Text Content with typewriter effect feel
            VStack(spacing: 16) {
                Text(title.uppercased())
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .tracking(2)
                    .foregroundColor(.cleanTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.cleanTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 40)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 15)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showContent = true
            }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
        .onDisappear {
            showContent = false
            isAnimating = false
        }
    }
}

// MARK: - Severance Auth View (Full Screen)

struct SeveranceAuthView: View {
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case name, email, password, confirmPassword
    }
    
    @State private var isSignUp = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var animateLogo = false
    @State private var showForm = false
    
    var body: some View {
        ZStack {
            // Background
            Color.cleanBackground
                .ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                }
            
            // Subtle grid overlay
            GeometryReader { geo in
                ForEach(0..<15) { i in
                    Rectangle()
                        .fill(Color.cleanBorder.opacity(0.25))
                        .frame(width: 0.5)
                        .offset(x: CGFloat(i) * (geo.size.width / 14))
                }
            }
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    // Header with animated logo
                    VStack(spacing: 20) {
                        // Geometric logo animation
                        ZStack {
                            // Outer rotating ring
                            Circle()
                                .stroke(Color.cleanBorder, lineWidth: 1)
                                .frame(width: 110, height: 110)
                                .rotationEffect(.degrees(animateLogo ? 360 : 0))
                            
                            // Orange circle
                            Circle()
                                .fill(Color.cleanOrange)
                                .frame(width: 80, height: 80)
                                .shadow(color: Color.cleanOrange.opacity(0.25), radius: 16, x: 0, y: 8)
                            
                            // Icon
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(showForm ? 1 : 0.8)
                        .opacity(showForm ? 1 : 0)
                        
                        VStack(spacing: 8) {
                            Text("FITO")
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .tracking(8)
                                .foregroundColor(.cleanTextPrimary)
                            
                            Text("Your AI Personal Stylist")
                                .font(.system(size: 14, weight: .regular))
                                .tracking(1)
                                .foregroundColor(.cleanTextSecondary)
                        }
                        .opacity(showForm ? 1 : 0)
                        .offset(y: showForm ? 0 : 10)
                    }
                    .padding(.top, 60)
                    
                    // Auth Toggle - Minimal underline style
                    HStack(spacing: 0) {
                        AuthTabButton(title: "SIGN UP", isSelected: isSignUp) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isSignUp = true
                            }
                        }
                        
                        AuthTabButton(title: "SIGN IN", isSelected: !isSignUp) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isSignUp = false
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .opacity(showForm ? 1 : 0)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        if isSignUp {
                            SeveranceTextField(
                                placeholder: "Full Name",
                                text: $name,
                                icon: "person"
                            )
                            .focused($focusedField, equals: .name)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                        
                        SeveranceTextField(
                            placeholder: "Email Address",
                            text: $email,
                            icon: "envelope",
                            keyboardType: .emailAddress
                        )
                        .focused($focusedField, equals: .email)
                        
                        SeveranceTextField(
                            placeholder: "Password",
                            text: $password,
                            icon: "lock",
                            isSecure: true
                        )
                        .focused($focusedField, equals: .password)
                        
                        if isSignUp {
                            SeveranceTextField(
                                placeholder: "Confirm Password",
                                text: $confirmPassword,
                                icon: "lock.shield",
                                isSecure: true
                            )
                            .focused($focusedField, equals: .confirmPassword)
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }
                    .padding(.horizontal, 32)
                    .opacity(showForm ? 1 : 0)
                    .animation(.spring(response: 0.4), value: isSignUp)
                    
                    // Primary Action Button
                    Button {
                        performAuth()
                    } label: {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Text(isSignUp ? "CREATE ACCOUNT" : "SIGN IN")
                                    .font(.system(size: 15, weight: .semibold))
                                    .tracking(1.5)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.cleanOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 32)
                    .opacity(showForm ? 1 : 0)
                    
                    // Terms
                    Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                        .font(.system(size: 11))
                        .foregroundColor(.cleanTextTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 48)
                        .opacity(showForm ? 1 : 0)
                    
                    Spacer(minLength: 40)
                }
            }
            
            // Close Button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.cleanTextSecondary)
                            .frame(width: 40, height: 40)
                            .background(Color.cleanCardBg)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.cleanBorder, lineWidth: 1)
                            )
                    }
                    .padding(.trailing, 24)
                    .padding(.top, 16)
                }
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showForm = true
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                animateLogo = true
            }
        }
        .alert("Oops!", isPresented: $showError) {
            Button("Try Again", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func performAuth() {
        focusedField = nil
        
        let emailRegex = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            showError = true
            return
        }
        
        guard email.wholeMatch(of: emailRegex) != nil else {
            errorMessage = "Please enter a valid email address"
            showError = true
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter a password"
            showError = true
            return
        }
        
        if isSignUp {
            guard !name.isEmpty else {
                errorMessage = "Please enter your name"
                showError = true
                return
            }
            
            guard password == confirmPassword else {
                errorMessage = "Passwords don't match"
                showError = true
                return
            }
            
            guard password.count >= 8 else {
                errorMessage = "Password must be at least 8 characters"
                showError = true
                return
            }
        }
        
        isLoading = true
        
        Task {
            do {
                if isSignUp {
                    try await authService.signUp(email: email, password: password, name: name)
                } else {
                    try await authService.signIn(email: email, password: password)
                }
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch let authError as AuthError {
                await MainActor.run {
                    isLoading = false
                    switch authError {
                    case .emailAlreadyInUse:
                        errorMessage = "An account with this email already exists. Try signing in instead."
                    default:
                        errorMessage = authError.localizedDescription
                    }
                    showError = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Auth Tab Button

struct AuthTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(isSelected ? .cleanTextPrimary : .cleanTextTertiary)
                
                Rectangle()
                    .fill(isSelected ? Color.cleanOrange : Color.clear)
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Severance Text Field

struct SeveranceTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String = ""
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    @State private var isSecureVisible = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(isFocused ? .cleanOrange : .cleanTextTertiary)
                    .frame(width: 20)
                
                // Text field
                if isSecure && !isSecureVisible {
                    SecureField(placeholder, text: $text)
                        .font(.system(size: 16))
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .font(.system(size: 16))
                        .keyboardType(keyboardType)
                        .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                }
                
                // Toggle visibility for password
                if isSecure {
                    Button {
                        isSecureVisible.toggle()
                    } label: {
                        Image(systemName: isSecureVisible ? "eye.slash" : "eye")
                            .font(.system(size: 14))
                            .foregroundColor(.cleanTextTertiary)
                    }
                }
            }
            .padding(.bottom, 12)
            
            // Underline
            Rectangle()
                .fill(isFocused ? Color.cleanOrange : Color.cleanBorder)
                .frame(height: isFocused ? 2 : 1)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

// MARK: - Preview

#Preview {
    CleanOnboardingView(authService: AuthService.shared)
}
