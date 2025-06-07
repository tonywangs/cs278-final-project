//
//  BlockedUsersView.swift
//  ProductivityTracker
//
//  Created by Assistant on 06/06/2025.
//

import SwiftUI

struct BlockedUsersView: View {
    let blocked: [UserProfile]
    let onUnblock: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.parchment.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Blocked Users")
                            .font(.custom("Georgia-Bold", size: 28))
                            .foregroundColor(Theme.logoColor)
                        
                        Text("Users you've blocked cannot follow you or find your profile")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    
                    // Content
                    if blocked.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "person.fill.checkmark")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No Blocked Users")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("You haven't blocked anyone yet")
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(blocked) { userProfile in
                                    BlockedUserCard(
                                        userProfile: userProfile,
                                        onUnblock: {
                                            onUnblock(userProfile.uid)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.logoColor)
                    .font(.system(size: 16, weight: .medium))
                }
            }
        }
    }
}

struct BlockedUserCard: View {
    let userProfile: UserProfile
    let onUnblock: () -> Void
    @State private var showingUnblockAlert = false
    
    var body: some View {
        HStack {
            // User avatar
            ProfileImageView(
                imageURL: userProfile.profileImageURL,
                username: userProfile.username,
                size: 40
            )
            
            // User info
            VStack(alignment: .leading, spacing: 2) {
                Text("@\(userProfile.username)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.darkAccentColor)
                
                Text("Blocked user")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Spacer()
            
            // Unblock button
            Button(action: { showingUnblockAlert = true }) {
                Text("Unblock")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.2), lineWidth: 1.5)
        )
        .alert("Unblock User", isPresented: $showingUnblockAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Unblock", role: .destructive) {
                onUnblock()
            }
        } message: {
            Text("Are you sure you want to unblock @\(userProfile.username)? They will be able to follow you and find your profile again.")
        }
    }
}

#Preview {
    BlockedUsersView(
        blocked: [
            UserProfile(uid: "1", username: "blockeduser1"),
            UserProfile(uid: "2", username: "blockeduser2")
        ],
        onUnblock: { _ in }
    )
} 