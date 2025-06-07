//
//  ProfileImageView.swift
//  ProductivityTracker
//
//  Created by Assistant on 06/06/2025.
//

import SwiftUI

struct ProfileImageView: View {
    let imageURL: String?
    let username: String
    let size: CGFloat
    
    init(imageURL: String?, username: String, size: CGFloat = 40) {
        self.imageURL = imageURL
        self.username = username
        self.size = size
    }
    
    var body: some View {
        AsyncImage(url: URL(string: imageURL ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            // Fallback to initials
            Circle()
                .fill(Theme.darkAccentColor.opacity(0.1))
                .overlay(
                    Text(String(username.prefix(1)).uppercased())
                        .font(.system(size: size * 0.4, weight: .bold))
                        .foregroundColor(Theme.darkAccentColor)
                )
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        ProfileImageView(imageURL: nil, username: "Katie", size: 80)
        ProfileImageView(imageURL: "https://via.placeholder.com/150", username: "John", size: 50)
        ProfileImageView(imageURL: nil, username: "Test", size: 30)
    }
    .padding()
} 