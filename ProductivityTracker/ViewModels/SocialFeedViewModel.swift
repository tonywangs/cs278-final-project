//
//  SocialFeedViewModel.swift
//  ProductivityTracker
//
//  Created by Katie Cheng on 07/05/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class SocialFeedViewModel: ObservableObject {
    @Published var friendEntries: [FriendProductivityEntry] = []
    @Published var commentInputs: [UUID: String] = [:]
    @Published var showCommentInput: [UUID: Bool] = [:]
    @Published var cheeredPosts: Set<UUID> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userHasStartedHourglass = false
    @Published var showingHourglassPrompt = false
    
    private let db = Firestore.firestore()
    
    init() {
        Task {
            await loadFeedData()
        }
        
        // Listen for hourglass data updates
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("HourglassDataUpdated"),
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.checkUserHourglassStatus()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func refreshFeed() async {
        // Recheck user's hourglass status first
        await checkUserHourglassStatus()
        
        // Then reload feed data regardless of hourglass status
        // This allows users to see new followers even if they haven't started their hourglass
        await loadFeedData()
    }
    
    func checkUserHourglassStatus() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: today)
        
        do {
            let currentUserProductivityDocId = "\(currentUser.uid)_\(todayStr)"
            let currentUserProductivityDoc = try await db.collection("productivity").document(currentUserProductivityDocId).getDocument()
            
            let hasStartedHourglass = currentUserProductivityDoc.exists && 
                                    currentUserProductivityDoc.data()?["hourglassData"] != nil
            
            await MainActor.run {
                let wasShowingPrompt = self.showingHourglassPrompt
                self.userHasStartedHourglass = hasStartedHourglass
                self.showingHourglassPrompt = !hasStartedHourglass
                
                // If user just started their hourglass, refresh the feed
                if wasShowingPrompt && hasStartedHourglass {
                    Task {
                        await self.loadFeedData()
                    }
                }
            }
        } catch {
            print("Error checking user hourglass status: \(error)")
        }
    }
    
    private func loadFeedData() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        guard let currentUser = Auth.auth().currentUser else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Not authenticated"
            }
            return
        }
        
        do {
            // Get today's date string
            let today = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let todayStr = formatter.string(from: today)
            
            // First, check if current user has started their hourglass today
            let currentUserProductivityDocId = "\(currentUser.uid)_\(todayStr)"
            let currentUserProductivityDoc = try await db.collection("productivity").document(currentUserProductivityDocId).getDocument()
            
            let hasStartedHourglass = currentUserProductivityDoc.exists && 
                                    currentUserProductivityDoc.data()?["hourglassData"] != nil
            
            await MainActor.run {
                self.userHasStartedHourglass = hasStartedHourglass
                self.showingHourglassPrompt = !hasStartedHourglass
            }
            
            // If user hasn't started their hourglass, don't load feed data
            if !hasStartedHourglass {
                await MainActor.run {
                    self.friendEntries = []
                    self.isLoading = false
                }
                return
            }
            
            // Get current user's following list from Firestore
            let userDoc = try await db.collection("users").document(currentUser.uid).getDocument()
            
            guard let userData = userDoc.data(),
                  let following = userData["following"] as? [String] else {
                await MainActor.run {
                    self.friendEntries = []
                    self.isLoading = false
                }
                return
            }
            
            if following.isEmpty {
                await MainActor.run {
                    self.friendEntries = []
                    self.isLoading = false
                }
                return
            }
            
            var feedEntries: [FriendProductivityEntry] = []
            
            // First, add the current user's own hourglass to the feed
            if let currentUserUsername = userData["username"] as? String,
               let currentUserProductivityData = currentUserProductivityDoc.data() {
                
                let currentUserProfileImageURL = userData["profileImageURL"] as? String
                
                let currentUserEntry = try await self.convertFirestoreToFeedEntry(
                    userId: currentUser.uid,
                    username: currentUserUsername,
                    profileImageURL: currentUserProfileImageURL,
                    date: today,
                    productivityData: currentUserProductivityData,
                    isMutualFollowing: true // User always has mutual access to their own data
                )
                
                feedEntries.append(currentUserEntry)
            }
            
            // Get productivity data for each followed user
            for followedUID in following {
                // Get user profile
                let userDoc = try await db.collection("users").document(followedUID).getDocument()
                guard let userProfileData = userDoc.data(),
                      let username = userProfileData["username"] as? String else {
                    continue
                }
                
                let profileImageURL = userProfileData["profileImageURL"] as? String
                
                // Check if this user follows back (mutual following)
                let theirFollowing = userProfileData["following"] as? [String] ?? []
                let isMutualFollowing = theirFollowing.contains(currentUser.uid)
                
                // Get today's productivity data
                let productivityDocId = "\(followedUID)_\(todayStr)"
                let productivityDoc = try await db.collection("productivity").document(productivityDocId).getDocument()
                
                if productivityDoc.exists,
                   let productivityData = productivityDoc.data() {
                    
                    // Convert Firestore data to our model
                    let entry = try await self.convertFirestoreToFeedEntry(
                        userId: followedUID,
                        username: username,
                        profileImageURL: profileImageURL,
                        date: today,
                        productivityData: productivityData,
                        isMutualFollowing: isMutualFollowing
                    )
                    
                    feedEntries.append(entry)
                } else {
                    // Even if no productivity data, show the user's profile with empty/default data
                    // This allows non-mutual followers to see that the user exists
                    let emptyEntry = FriendProductivityEntry(
                        userId: followedUID,
                        username: username,
                        profileImageURL: profileImageURL,
                        date: today,
                        entries: [], // Empty entries will show as gray squares
                        lastUpdated: Date(),
                        isMutualFollowing: isMutualFollowing
                    )
                    feedEntries.append(emptyEntry)
                }
            }
            
            // Sort by most recent update
            feedEntries.sort { $0.lastUpdated > $1.lastUpdated }
            
            await MainActor.run {
                self.friendEntries = feedEntries
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                // Fall back to mock data for development
                self.loadMockData()
            }
        }
    }
    
    private func convertFirestoreToFeedEntry(userId: String, username: String, profileImageURL: String?, date: Date, productivityData: [String: Any], isMutualFollowing: Bool) async throws -> FriendProductivityEntry {
        
        // Extract hourglass data
        guard let hourglassData = productivityData["hourglassData"] as? [String: [String: Any]] else {
            throw NSError(domain: "DataError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid hourglass data"])
        }
        
        let lastUpdated = (productivityData["lastUpdated"] as? Timestamp)?.dateValue() ?? Date()
        
        // Convert hourglass data to ProductivityEntry array
        var entries: [ProductivityEntry] = []
        
        for (hourStr, activityData) in hourglassData {
            guard let hour = Int(hourStr),
                  let activityName = activityData["name"] as? String,
                  let colorData = activityData["color"] as? [String: Double] else {
                continue
            }
            
            let activityColor = ColorCodable(
                red: colorData["red"] ?? 0,
                green: colorData["green"] ?? 0,
                blue: colorData["blue"] ?? 0,
                opacity: colorData["opacity"] ?? 1
            )
            
            let activity = ActivityCategory(
                name: activityName,
                color: activityColor
            )
            
            // Create entries for both 30-minute slots in this hour
            entries.append(ProductivityEntry(
                userId: userId,
                date: date,
                timeSlot: hour * 2,
                category: activity
            ))
            entries.append(ProductivityEntry(
                userId: userId,
                date: date,
                timeSlot: hour * 2 + 1,
                category: activity
            ))
        }
        
        return FriendProductivityEntry(
            userId: userId,
            username: username,
            profileImageURL: profileImageURL,
            date: date,
            entries: entries,
            lastUpdated: lastUpdated,
            isMutualFollowing: isMutualFollowing
        )
    }
    
    func addComment(_ comment: String, to entry: FriendProductivityEntry) {
        guard let currentUser = Auth.auth().currentUser,
              let idx = friendEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        
        // Get current user's username
        Task {
            do {
                let userDoc = try await db.collection("users").document(currentUser.uid).getDocument()
                if let userData = userDoc.data(),
                   let username = userData["username"] as? String {
                    
                    let newComment = Comment(
                        text: comment,
                        authorId: currentUser.uid,
                        authorUsername: username
                    )
                    
                    await MainActor.run {
                        self.friendEntries[idx].comments.append(newComment)
                        self.commentInputs[entry.id] = ""
                        self.showCommentInput[entry.id] = false
                    }
                    
                    // TODO: Save comment to Firestore for persistence
                    // This will be implemented in future updates
                }
            } catch {
                print("Error adding comment: \(error)")
            }
        }
    }
    
    func toggleCheer(for entry: FriendProductivityEntry) {
        guard let idx = friendEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        if cheeredPosts.contains(entry.id) {
            friendEntries[idx].cheerCount = max(0, friendEntries[idx].cheerCount - 1)
            cheeredPosts.remove(entry.id)
        } else {
            friendEntries[idx].cheerCount += 1
            cheeredPosts.insert(entry.id)
        }
    }
    
    // Keep mock data for development/fallback
    private func loadMockData() {
        // Your existing mock data implementation...
        let mockEntries = [
            FriendProductivityEntry(
                userId: "user1",
                username: "Tony Wang",
                profileImageURL: nil,
                date: Date(),
                entries: generateMockEntries(),
                lastUpdated: Date(),
                comments: [
                    Comment(text: "This is so colorful! Love your routine.", authorId: "user3", authorUsername: "Sarah Kim", timestamp: Date().addingTimeInterval(-3600))
                ],
                cheerCount: 2,
                isMutualFollowing: true // Mutual following - can see hourglass
            ),
            FriendProductivityEntry(
                userId: "user2",
                username: "Sheryl Chen",
                profileImageURL: nil,
                date: Date().addingTimeInterval(-86400),
                entries: generateMockEntries(),
                lastUpdated: Date().addingTimeInterval(-86400),
                comments: [],
                cheerCount: 0,
                isMutualFollowing: false // Not mutual - will show blurred
            )
        ]
        
        friendEntries = mockEntries
    }
    
    private func generateMockEntries() -> [ProductivityEntry] {
        var entries: [ProductivityEntry] = []
        
        for slot in 0..<48 {
            let hour = slot / 2
            let activity: ActivityCategory
            
            switch hour {
            case 0...5:
                activity = ActivityCategory(name: "Sleep", color: ColorCodable(color: .black))
            case 6...7:
                activity = ActivityCategory(name: "Meals", color: ColorCodable(color: .yellow))
            case 8...11:
                activity = ActivityCategory(name: "Classes", color: ColorCodable(color: .green))
            case 12:
                activity = ActivityCategory(name: "Meals", color: ColorCodable(color: .yellow))
            case 13...17:
                activity = ActivityCategory(name: "Study", color: ColorCodable(color: .blue))
            case 18...20:
                activity = ActivityCategory(name: "Social", color: ColorCodable(color: .pink))
            case 21...22:
                activity = ActivityCategory(name: "Social Media", color: ColorCodable(color: .red))
            case 23:
                activity = ActivityCategory(name: "Sleep", color: ColorCodable(color: .black))
            default:
                activity = ActivityCategory(name: "Sleep", color: ColorCodable(color: .black))
            }
            
            entries.append(ProductivityEntry(
                userId: "current_user",
                date: Date(),
                timeSlot: slot,
                category: activity
            ))
        }
        return entries
    }
} 