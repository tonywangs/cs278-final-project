//
//  User.swift
//  ProductivityTracker
//
//  Created by Katie Cheng on 07/05/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct User: Identifiable, Codable {
    let uid: String
    let email: String
    let username: String
    var following: [String] // Array of UIDs this user follows
    var followers: [String] // Array of UIDs following this user
    var createdAt: Date
    var lastActive: Date
    
    var id: String { uid }
    
    // Custom coding keys to handle Firestore timestamp conversion
    private enum CodingKeys: String, CodingKey {
        case uid, email, username, following, followers, createdAt, lastActive
    }
    
    // Custom decoder to handle Firestore Timestamp conversion
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uid = try container.decode(String.self, forKey: .uid)
        email = try container.decode(String.self, forKey: .email)
        username = try container.decode(String.self, forKey: .username)
        following = try container.decodeIfPresent([String].self, forKey: .following) ?? []
        followers = try container.decodeIfPresent([String].self, forKey: .followers) ?? []
        
        // Handle Date fields that might be Firestore Timestamps or regular Dates
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .lastActive) {
            lastActive = timestamp.dateValue()
        } else {
            lastActive = try container.decodeIfPresent(Date.self, forKey: .lastActive) ?? Date()
        }
    }
    
    // Custom encoder to ensure proper Firestore storage
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(uid, forKey: .uid)
        try container.encode(email, forKey: .email)
        try container.encode(username, forKey: .username)
        try container.encode(following, forKey: .following)
        try container.encode(followers, forKey: .followers)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastActive, forKey: .lastActive)
    }
    
    init(uid: String, email: String, username: String, following: [String] = [], followers: [String] = []) {
        self.uid = uid
        self.email = email
        self.username = username
        self.following = following
        self.followers = followers
        self.createdAt = Date()
        self.lastActive = Date()
    }
    
    // Convert from Firebase Auth User
    init(from firebaseUser: FirebaseAuth.User, username: String) {
        self.uid = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.username = username
        self.following = []
        self.followers = []
        self.createdAt = Date()
        self.lastActive = Date()
    }
}

// For displaying in UI
struct UserProfile: Identifiable, Codable {
    let uid: String
    let username: String
    
    var id: String { uid }
} 