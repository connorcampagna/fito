//
//  VirtualTryOnView.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  AI Virtual Try-On - Severance Style
//

import SwiftUI
import PhotosUI

struct VirtualTryOnView: View {
    @StateObject private var tryOnService = VirtualTryOnService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var personImage: UIImage?
    @State private var clothingImage: UIImage?
    @State private var showingPersonPicker = false
    @State private var showingClothingPicker = false
    @State private var selectedPersonItem: PhotosPickerItem?
    @State private var selectedClothingItem: PhotosPickerItem?
    @State private var showingSaveSuccess = false
    @State private var showingSubscriptionSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Stark white background
                Color.cleanBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Header
                        headerSection
                        
                        // Image Upload Section
                        imageUploadSection
                        
                        // Generate Button
                        generateButton
                        
                        // Result Section
                        resultSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .photosPicker(isPresented: $showingPersonPicker, selection: $selectedPersonItem, matching: .images)
            .photosPicker(isPresented: $showingClothingPicker, selection: $selectedClothingItem, matching: .images)
            .onChange(of: selectedPersonItem) { _, newItem in
                loadImage(from: newItem) { image in
                    personImage = image
                }
            }
            .onChange(of: selectedClothingItem) { _, newItem in
                loadImage(from: newItem) { image in
                    clothingImage = image
                }
            }
            .alert("Saved!", isPresented: $showingSaveSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The try-on image has been saved to your photos.")
            }
            .sheet(isPresented: $showingSubscriptionSheet) {
                SubscriptionPlansView()
            }
        }
    }
    
    // MARK: - Header Section (Severance Style)
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("STYLE STUDIO")
                .font(.system(size: 24, weight: .bold))
                .tracking(2)
                .foregroundColor(.cleanTextPrimary)
            
            Text("See how any piece of clothing looks on you instantly")
                .font(.system(size: 14))
                .foregroundColor(.cleanTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Image Upload Section (Severance Style)
    
    private var imageUploadSection: some View {
        HStack(spacing: 16) {
            // Person Photo Card
            imageUploadCard(
                title: "YOUR PHOTO",
                image: personImage,
                icon: "person.fill",
                action: { showingPersonPicker = true }
            )
            
            // Clothing Photo Card
            imageUploadCard(
                title: "CLOTHING",
                image: clothingImage,
                icon: "tshirt.fill",
                action: { showingClothingPicker = true }
            )
        }
    }
    
    private func imageUploadCard(title: String, image: UIImage?, icon: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            ZStack {
                // Card background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(height: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cleanBorder, lineWidth: 1)
                    )
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack(spacing: 12) {
                        // Geometric icon container
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.cleanBorder, lineWidth: 1)
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: icon)
                                .font(.system(size: 20))
                                .foregroundColor(.cleanTextTertiary)
                        }
                        
                        Text(title)
                            .font(.system(size: 11, weight: .medium))
                            .tracking(0.5)
                            .foregroundColor(.cleanTextSecondary)
                    }
                }
                
                // Add button overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: action) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.cleanOrange)
                                .clipShape(Circle())
                        }
                        .offset(x: 6, y: 6)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Generate Button (Severance Style)
    
    private var generateButton: some View {
        Button(action: generateTryOn) {
            HStack(spacing: 12) {
                if tryOnService.isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("GENERATE TRY-ON")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(1)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(canGenerate ? Color.cleanOrange : Color.cleanTextTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!canGenerate || tryOnService.isGenerating)
    }
    
    private var canGenerate: Bool {
        personImage != nil && clothingImage != nil
    }
    
    // MARK: - Result Section (Severance Style)
    
    private var resultSection: some View {
        VStack(spacing: 16) {
            if tryOnService.isGenerating {
                // Loading state
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .frame(height: 280)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cleanBorder, lineWidth: 1)
                            )
                        
                        VStack(spacing: 20) {
                            // Rotating geometric icon
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cleanOrange.opacity(0.3), lineWidth: 1)
                                    .frame(width: 60, height: 60)
                                    .rotationEffect(.degrees(45))
                                
                                Image(systemName: "sparkles")
                                    .font(.system(size: 24))
                                    .foregroundColor(.cleanOrange)
                            }
                            
                            Text(tryOnService.statusMessage.isEmpty ? "GENERATING..." : tryOnService.statusMessage.uppercased())
                                .font(.system(size: 12, weight: .medium))
                                .tracking(1)
                                .foregroundColor(.cleanTextPrimary)
                            
                            // Progress bar
                            VStack(spacing: 8) {
                                ProgressView(value: tryOnService.progress)
                                    .tint(.cleanOrange)
                                    .frame(width: 180)
                                
                                Text("This may take up to 30 seconds")
                                    .font(.system(size: 11))
                                    .foregroundColor(.cleanTextTertiary)
                            }
                        }
                    }
                }
            } else if let generatedImage = tryOnService.generatedImage {
                // Result image
                VStack(spacing: 16) {
                    Image(uiImage: generatedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 380)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cleanBorder, lineWidth: 1)
                        )
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: saveImage) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.down")
                                Text("SAVE")
                                    .tracking(0.5)
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.cleanOrange)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.cleanOrange, lineWidth: 1.5)
                            )
                        }
                        
                        Button(action: shareImage) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("SHARE")
                                    .tracking(0.5)
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.cleanTextPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.cleanBorder, lineWidth: 1)
                            )
                        }
                    }
                }
            } else if let error = tryOnService.error {
                // Error state
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .frame(height: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(error as? TryOnError == .subscriptionRequired ? Color.cleanOrange : Color.red.opacity(0.5), lineWidth: 1)
                            )
                        
                        VStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(error as? TryOnError == .subscriptionRequired ? Color.cleanOrange : Color.red.opacity(0.5), lineWidth: 1)
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: error as? TryOnError == .subscriptionRequired ? "crown.fill" : "exclamationmark.triangle")
                                    .font(.system(size: 20))
                                    .foregroundColor(error as? TryOnError == .subscriptionRequired ? .cleanOrange : .red)
                            }
                            
                            Text(error.localizedDescription)
                                .font(.system(size: 13))
                                .foregroundColor(.cleanTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                            
                            // Show upgrade button for subscription error
                            if case .subscriptionRequired = error as? TryOnError {
                                Button(action: { showingSubscriptionSheet = true }) {
                                    Text("UPGRADE TO PRO")
                                        .font(.system(size: 12, weight: .semibold))
                                        .tracking(1)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(Color.cleanOrange)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }
            } else {
                // Empty state
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .frame(height: 180)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cleanBorder, lineWidth: 1)
                        )
                    
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.cleanBorder, lineWidth: 1)
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 20))
                                .foregroundColor(.cleanTextTertiary)
                        }
                        
                        Text("Your generation will appear here")
                            .font(.system(size: 13))
                            .foregroundColor(.cleanTextTertiary)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadImage(from item: PhotosPickerItem?, completion: @escaping (UIImage?) -> Void) {
        guard let item = item else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    completion(image)
                }
            }
        }
    }
    
    private func generateTryOn() {
        guard let person = personImage, let clothing = clothingImage else { return }
        
        HapticFeedback.medium()
        
        Task {
            do {
                _ = try await tryOnService.generateTryOn(personImage: person, clothingImage: clothing)
                HapticFeedback.success()
            } catch {
                HapticFeedback.error()
            }
        }
    }
    
    private func saveImage() {
        guard let image = tryOnService.generatedImage else { return }
        tryOnService.saveToPhotos(image)
        showingSaveSuccess = true
        HapticFeedback.success()
    }
    
    private func shareImage() {
        guard let image = tryOnService.generatedImage else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Preview

#Preview {
    VirtualTryOnView()
}
