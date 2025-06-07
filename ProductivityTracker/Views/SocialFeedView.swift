//
//  SocialFeedView.swift
//  ProductivityTracker
//
//  Created by Katie Cheng on 07/05/2025.
//

import SwiftUI
import FirebaseAuth

struct SocialFeedView: View {
    @StateObject private var viewModel = SocialFeedViewModel()
    
    var body: some View {
        ZStack {
            Theme.parchment.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("hourglass")
                        .font(.custom("Georgia-Bold", size: 32))
                        .foregroundColor(Theme.logoColor)
                        .padding(.leading)
                    Spacer()
                }
                .padding(.top, 12)
                NavigationView {
                    ScrollView {
                        VStack {
                            if viewModel.isLoading && viewModel.friendEntries.isEmpty {
                                VStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Text("Loading feed...")
                                        .foregroundColor(.gray)
                                        .padding(.top)
                                }
                                .frame(maxWidth: .infinity, minHeight: 400)
                            } else if viewModel.showingHourglassPrompt {
                                VStack(spacing: 20) {
                                    Image(systemName: "hourglass")
                                        .font(.system(size: 64))
                                        .foregroundColor(Theme.logoColor)
                                    
                                    Text("Start Your Hourglass First!")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Theme.darkAccentColor)
                                    
                                    Text("You need to start coloring your own hourglass before you can see what your friends are up to.")
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 32)
                                    
                                    Text("Pull down to refresh once you've started!")
                                        .font(.caption)
                                        .foregroundColor(Theme.logoColor)
                                        .padding(.top, 4)
                                    
                                    Button(action: {
                                        // Post notification to switch to hourglass tab
                                        NotificationCenter.default.post(name: NSNotification.Name("SwitchToHourglassTab"), object: nil)
                                    }) {
                                        HStack {
                                            Image(systemName: "paintbrush")
                                            Text("Go to My Hourglass")
                                        }
                                        .padding()
                                        .background(Theme.logoColor)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                    .padding(.top, 8)
                                }
                                .frame(maxWidth: .infinity, minHeight: 400)
                            } else if viewModel.friendEntries.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "person.2.slash")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray)
                                    Text("No one to follow yet!")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                    Text("Search for friends in your Profile tab")
                                        .foregroundColor(.gray)
                                    
                                    Text("Pull down to refresh once you're following someone!")
                                        .font(.caption)
                                        .foregroundColor(Theme.logoColor)
                                        .padding(.top, 8)
                                }
                                .frame(maxWidth: .infinity, minHeight: 400)
                            } else {
                                LazyVStack {
                                    ForEach(viewModel.friendEntries) { entry in
                                        FriendProductivityCard(viewModel: viewModel, entry: entry)
                                            .padding(.horizontal)
                                            .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Theme.parchment)
                    .refreshable {
                        await viewModel.refreshFeed()
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
        }
        .environment(\.font, .custom("Georgia", size: 18))
    }
}

struct FriendProductivityCard: View {
    @ObservedObject var viewModel: SocialFeedViewModel
    let entry: FriendProductivityEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ProfileImageView(
                    imageURL: entry.profileImageURL,
                    username: entry.userName,
                    size: 40
                )
                VStack(alignment: .leading) {
                    HStack {
                        Text(entry.userName)
                            .font(.system(size: 20))
                            .foregroundColor(Theme.darkAccentColor)
                        if entry.userId == Auth.auth().currentUser?.uid {
                            Text("(You)")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.logoColor)
                                .italic()
                        }
                    }
                    Text("Updated \(timeAgoString(from: entry.lastUpdated))")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.logoColor)
                }
            }
            
            // Show either the real hourglass or blurred version based on mutual following
            if entry.isMutualFollowing {
                GlassyProductivityGridPreview(entries: entry.entries)
                    .padding(8)
            } else {
                BlurredProductivityPreview(entries: entry.entries)
                    .padding(8)
            }
            
            // Comments Section - only show if mutual following
            if entry.isMutualFollowing && !entry.comments.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(entry.comments) { comment in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "bubble.left.fill")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .foregroundColor(Theme.logoColor)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("@\(comment.authorUsername)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Theme.logoColor)
                                    Spacer()
                                    Text(timeAgoString(from: comment.timestamp))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Text(comment.text)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.top, 4)
            }
            
            // Comment input - only show if mutual following
            if entry.isMutualFollowing && (viewModel.showCommentInput[entry.id] ?? false) {
                HStack {
                    TextField("Add a comment...", text: Binding(
                        get: { viewModel.commentInputs[entry.id] ?? "" },
                        set: { viewModel.commentInputs[entry.id] = $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Post") {
                        if let text = viewModel.commentInputs[entry.id], !text.trimmingCharacters(in: .whitespaces).isEmpty {
                            viewModel.addComment(text, to: entry)
                        }
                    }
                    .foregroundColor(Theme.logoColor)
                }
                .padding(.top, 4)
            }
            
            // Action buttons - only show if mutual following
            if entry.isMutualFollowing {
                HStack {
                    Button(action: {
                        viewModel.toggleCheer(for: entry)
                    }) {
                        HStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(viewModel.cheeredPosts.contains(entry.id) ? Theme.darkAccentColor : Color.clear)
                                    .frame(width: 32, height: 32)
                                Image(systemName: "face.smiling")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(viewModel.cheeredPosts.contains(entry.id) ? Theme.parchment : Theme.darkAccentColor)
                            }
                            Text("Cheer")
                                .foregroundColor(viewModel.cheeredPosts.contains(entry.id) ? Theme.darkAccentColor : Theme.logoColor)
                            Text("\(entry.cheerCount)")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(viewModel.cheeredPosts.contains(entry.id) ? Theme.darkAccentColor : Theme.logoColor)
                                .padding(.leading, 2)
                                .padding(.trailing, 4)
                                .background(
                                    Capsule()
                                        .fill(viewModel.cheeredPosts.contains(entry.id) ? Theme.parchment : Color(.systemGray6))
                                )
                        }
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                    Button(action: {
                        viewModel.showCommentInput[entry.id] = true
                    }) {
                        Label("Comment", systemImage: "message")
                    }
                }
                .foregroundColor(Theme.logoColor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct GlassyProductivityGridPreview: View {
    let entries: [ProductivityEntry]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 8)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(0..<24) { hour in
                if let entry = entries.first(where: { $0.timeSlot / 2 == hour }) {
                    GlassyActivitySquare(entry: entry, hour: hour)
                } else {
                    EmptyTimeSquare(hour: hour)
                }
            }
        }
    }
}

struct GlassyActivitySquare: View {
    let entry: ProductivityEntry
    let hour: Int
    
    var body: some View {
        ZStack {
            // Base color with glass effect
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: adjustedActivityColor.opacity(0.8), location: 0.0),
                            .init(color: adjustedActivityColor.opacity(0.6), location: 0.5),
                            .init(color: adjustedActivityColor.opacity(0.9), location: 1.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .aspectRatio(1, contentMode: .fit)
            
            // Glass overlay effect
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.3), location: 0.0),
                            .init(color: Color.white.opacity(0.1), location: 0.5),
                            .init(color: Color.clear, location: 1.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Subtle border
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
            
            // Center icon and position time text at bottom
            VStack(spacing: 4) {
                // Centered activity icon
                if let iconName = getActivityIcon(for: entry.category.name) {
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(getIconColor(for: entry.category.name))
                        .opacity(0.7)
                }
                
                // Time label close to icon
                Text(formatHour(hour))
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(getIconColor(for: entry.category.name))
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 0)
            }
        }
        .shadow(color: adjustedActivityColor.opacity(0.3), radius: 2, x: 0, y: 1)
    }
    
    private func formatHour(_ hour: Int) -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ha"
        
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        
        if let date = calendar.date(from: components) {
            return dateFormatter.string(from: date).uppercased()
        }
        return "\(hour):00"
    }
    
    private var adjustedActivityColor: Color {
        let lowercaseName = entry.category.name.lowercased()
        if lowercaseName == "sleep" {
            return Color(red: 0.1, green: 0.1, blue: 0.1) // Much darker black
        }
        return entry.category.color.color
    }
    
    private func getActivityIcon(for activityName: String) -> String? {
        let lowercaseName = activityName.lowercased()
        switch lowercaseName {
        case "sleep":
            return "bed.double.fill"
        case "study":
            return "book.fill"
        case "exercise":
            return "figure.run"
        case "social":
            return "person.2.fill"
        case "work":
            return "laptopcomputer"
        default:
            return nil // No icon for custom activities
        }
    }
    
    private func getIconColor(for activityName: String) -> Color {
        let lowercaseName = activityName.lowercased()
        
        // Special case for sleep - use black icon
        if lowercaseName == "sleep" {
            return Color.black
        }
        
        // For other activities, calculate contrasting color
        let backgroundColor = entry.category.color.color
        let uiColor = UIColor(backgroundColor)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // If the background is dark, make icon lighter; if light, make icon darker
        if brightness < 0.5 {
            return Color(hue: Double(hue), saturation: Double(saturation * 0.8), brightness: Double(min(brightness + 0.3, 1.0)))
        } else {
            return Color(hue: Double(hue), saturation: Double(saturation * 1.2), brightness: Double(max(brightness - 0.4, 0.0)))
        }
    }
}

struct EmptyTimeSquare: View {
    let hour: Int
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
            
            // Time label for empty squares - centered
            Text(formatHour(hour))
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.gray)
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ha"
        
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        
        if let date = calendar.date(from: components) {
            return dateFormatter.string(from: date).uppercased()
        }
        return "\(hour):00"
    }
}

struct BlurredProductivityPreview: View {
    let entries: [ProductivityEntry]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 8)
    
    var body: some View {
        ZStack {
            // Blurred background hourglass with glassy effect
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<24) { hour in
                    if let entry = entries.first(where: { $0.timeSlot / 2 == hour }) {
                        GlassyActivitySquare(entry: entry, hour: hour)
                    } else {
                        EmptyTimeSquare(hour: hour)
                    }
                }
            }
            .blur(radius: 8)
            .opacity(0.6)
            
            // Overlay message
            VStack(spacing: 8) {
                Image(systemName: "eye.slash")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.darkAccentColor)
                
                Text("Private Hourglass")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.darkAccentColor)
                
                Text("This user needs to follow you back\nfor you to see their hourglass")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground).opacity(0.9))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
    }
}

struct Comment: Identifiable, Codable {
    let id: UUID
    let text: String
    let authorId: String
    let authorUsername: String
    let timestamp: Date
    
    init(id: UUID = UUID(), text: String, authorId: String, authorUsername: String, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.authorId = authorId
        self.authorUsername = authorUsername
        self.timestamp = timestamp
    }
}

struct FriendProductivityEntry: Identifiable, Codable {
    let id: UUID
    let userId: String
    let username: String
    let profileImageURL: String?
    let date: Date
    let entries: [ProductivityEntry]
    let lastUpdated: Date
    var comments: [Comment] // Changed from [String] to [Comment]
    var cheerCount: Int
    let isMutualFollowing: Bool // Whether this user follows back
    
    // For backward compatibility with existing UI
    var userName: String { username }
    
    init(id: UUID = UUID(), userId: String, username: String, profileImageURL: String? = nil, date: Date, entries: [ProductivityEntry], lastUpdated: Date, comments: [Comment] = [], cheerCount: Int = 0, isMutualFollowing: Bool = false) {
        self.id = id
        self.userId = userId
        self.username = username
        self.profileImageURL = profileImageURL
        self.date = date
        self.entries = entries
        self.lastUpdated = lastUpdated
        self.comments = comments
        self.cheerCount = cheerCount
        self.isMutualFollowing = isMutualFollowing
    }
}

// All ViewModel logic is now in SocialFeedViewModel.swift

// Helper function to show time ago
func timeAgoString(from date: Date) -> String {
    let now = Date()
    let timeInterval = now.timeIntervalSince(date)
    
    if timeInterval < 60 {
        return "just now"
    } else if timeInterval < 3600 {
        let minutes = Int(timeInterval / 60)
        return "\(minutes)m ago"
    } else if timeInterval < 86400 {
        let hours = Int(timeInterval / 3600)
        return "\(hours)h ago"
    } else {
        let days = Int(timeInterval / 86400)
        return "\(days)d ago"
    }
}

#Preview {
    SocialFeedView()
}

