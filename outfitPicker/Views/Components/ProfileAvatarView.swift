//
//  ProfileAvatarView.swift
//  outfitPicker
//
//  Shared avatar component used in Home and Profile
//

import SwiftUI

struct ProfileAvatarView: View {
    let profileImagePath: String?
    let name: String
    let size: CGFloat
    
    @State private var profileImage: UIImage?
    
    var body: some View {
        Group {
            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.cleanOrange, .cleanOrangeLight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
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
                    .frame(width: size, height: size)
                    .overlay {
                        Text(String(name.prefix(1).uppercased()))
                            .font(.system(size: size * 0.4, weight: .bold))
                            .foregroundColor(.cleanOrange)
                    }
            }
        }
        .onAppear { loadImage() }
    }
    
    private func loadImage() {
        guard let path = profileImagePath else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let loaded = ImageManager.shared.loadImage(from: path)
            DispatchQueue.main.async {
                profileImage = loaded
            }
        }
    }
}
