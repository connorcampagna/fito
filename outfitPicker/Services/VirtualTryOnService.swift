//
//  VirtualTryOnService.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//  Virtual Try-On via Backend (Nano Banana / FASHN API)
//

import Foundation
import UIKit

// MARK: - Virtual Try-On Service

@MainActor
final class VirtualTryOnService: ObservableObject {
    static let shared = VirtualTryOnService()
    
    @Published var isGenerating = false
    @Published var generatedImage: UIImage?
    @Published var error: TryOnError?
    @Published var progress: Double = 0
    @Published var statusMessage: String = ""
    
    private init() {}
    
    // MARK: - Generate Virtual Try-On
    
    func generateTryOn(personImage: UIImage, clothingImage: UIImage) async throws -> UIImage {
        isGenerating = true
        progress = 0
        error = nil
        generatedImage = nil
        statusMessage = "Preparing images..."
        
        defer { 
            isGenerating = false 
            progress = 1.0
            statusMessage = ""
        }
        
        // Get auth token
        guard let token = AuthService.shared.authToken else {
            throw TryOnError.unauthorized
        }
        
        // Convert images to base64
        guard let personData = personImage.jpegData(compressionQuality: 0.8),
              let clothingData = clothingImage.jpegData(compressionQuality: 0.8) else {
            throw TryOnError.invalidImage
        }
        
        let personBase64 = personData.base64EncodedString()
        let clothingBase64 = clothingData.base64EncodedString()
        
        progress = 0.15
        statusMessage = "Uploading to server..."
        
        // Create request to our backend
        let endpoint = "\(FitoConfig.backendURL)/tryon/generate"
        guard let url = URL(string: endpoint) else {
            throw TryOnError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 180 // 3 minutes for generation
        
        let body: [String: Any] = [
            "personImage": personBase64,
            "clothingImage": clothingBase64,
            "mode": "quality"
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        progress = 0.25
        statusMessage = "Generating try-on..."
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        progress = 0.8
        statusMessage = "Processing result..."
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TryOnError.networkError
        }
        
        // Parse error responses
        if httpResponse.statusCode != 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = json["error"] as? String {
                
                if httpResponse.statusCode == 401 {
                    throw TryOnError.unauthorized
                } else if httpResponse.statusCode == 403 {
                    throw TryOnError.subscriptionRequired
                } else if httpResponse.statusCode == 429 {
                    throw TryOnError.rateLimited
                } else {
                    throw TryOnError.serverError(errorMessage)
                }
            }
            throw TryOnError.serverError("Request failed with status \(httpResponse.statusCode)")
        }
        
        progress = 0.9
        
        // Parse success response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let resultBase64 = json["resultImage"] as? String else {
            throw TryOnError.invalidResponse
        }
        
        // Handle both base64 and URL responses
        var resultImage: UIImage?
        
        if resultBase64.hasPrefix("http") {
            // It's a URL, download the image
            if let imageUrl = URL(string: resultBase64) {
                let (imageData, _) = try await URLSession.shared.data(from: imageUrl)
                resultImage = UIImage(data: imageData)
            }
        } else {
            // It's base64 encoded
            if let imageData = Data(base64Encoded: resultBase64) {
                resultImage = UIImage(data: imageData)
            }
        }
        
        guard let finalImage = resultImage else {
            throw TryOnError.invalidResponse
        }
        
        progress = 1.0
        generatedImage = finalImage
        
        return finalImage
    }
    
    // MARK: - Save Generated Image
    
    func saveToPhotos(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    // MARK: - Clear Result
    
    func clearResult() {
        generatedImage = nil
        error = nil
        progress = 0
    }
}

// MARK: - Try-On Error

enum TryOnError: LocalizedError, Equatable {
    case invalidImage
    case invalidURL
    case networkError
    case unauthorized
    case subscriptionRequired
    case rateLimited
    case serverError(String)
    case invalidResponse
    case noApiKey
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not process the selected images"
        case .invalidURL:
            return "Invalid service URL"
        case .networkError:
            return "Network connection failed. Please check your internet."
        case .unauthorized:
            return "Please sign in to use virtual try-on"
        case .subscriptionRequired:
            return "Virtual try-on requires Fito Pro subscription"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .serverError(let message):
            return message
        case .invalidResponse:
            return "Could not process the result"
        case .noApiKey:
            return "Virtual try-on service not configured"
        }
    }
}
