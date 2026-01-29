//
//  ImageManager.swift
//  outfitPicker
//
//  Fito - Your AI-Powered Personal Stylist
//

import Foundation
import UIKit
import SwiftUI

/// Manages saving and loading images to/from the app's Documents directory
final class ImageManager {
    
    static let shared = ImageManager()
    
    private let fileManager = FileManager.default
    private let clothingImagesFolder = "ClothingImages"
    
    private init() {
        createClothingImagesFolderIfNeeded()
    }
    
    // MARK: - Directory Setup
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var clothingImagesDirectory: URL {
        documentsDirectory.appendingPathComponent(clothingImagesFolder)
    }
    
    private func createClothingImagesFolderIfNeeded() {
        let folderURL = clothingImagesDirectory
        if !fileManager.fileExists(atPath: folderURL.path) {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            } catch {
                print("Error creating clothing images folder: \(error)")
            }
        }
    }
    
    // MARK: - Save Image
    
    /// Saves an image to disk and returns the relative path
    /// - Parameter image: The UIImage to save
    /// - Returns: The relative path to the saved image, or nil if saving failed
    func saveImage(_ image: UIImage) -> String? {
        // Generate unique filename
        let filename = "\(UUID().uuidString).jpg"
        let relativePath = "\(clothingImagesFolder)/\(filename)"
        let fileURL = documentsDirectory.appendingPathComponent(relativePath)
        
        // Compress and save
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("Error: Could not convert image to JPEG data")
            return nil
        }
        
        do {
            try data.write(to: fileURL)
            return relativePath
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    // MARK: - Load Image
    
    /// Loads an image from a relative path
    /// - Parameter relativePath: The relative path to the image
    /// - Returns: The UIImage if found, nil otherwise
    func loadImage(from relativePath: String) -> UIImage? {
        let fileURL = documentsDirectory.appendingPathComponent(relativePath)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("Image file not found at path: \(relativePath)")
            return nil
        }
        
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    /// Returns the full file URL for a relative path
    func fullURL(for relativePath: String) -> URL {
        documentsDirectory.appendingPathComponent(relativePath)
    }
    
    // MARK: - Delete Image
    
    /// Deletes an image from disk
    /// - Parameter relativePath: The relative path to the image
    /// - Returns: True if deletion succeeded, false otherwise
    @discardableResult
    func deleteImage(at relativePath: String) -> Bool {
        let fileURL = documentsDirectory.appendingPathComponent(relativePath)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return true // Already deleted
        }
        
        do {
            try fileManager.removeItem(at: fileURL)
            return true
        } catch {
            print("Error deleting image: \(error)")
            return false
        }
    }
    
    // MARK: - Delete All Images
    
    /// Deletes all clothing images from disk
    func deleteAllImages() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: clothingImagesDirectory, includingPropertiesForKeys: nil)
            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Error deleting all images: \(error)")
        }
    }
}

// MARK: - SwiftUI Image Extension

extension Image {
    /// Creates an Image view from a clothing item's stored image path
    init(clothingImagePath: String) {
        if let uiImage = ImageManager.shared.loadImage(from: clothingImagePath) {
            self.init(uiImage: uiImage)
        } else {
            self.init(systemName: "photo")
        }
    }
}
