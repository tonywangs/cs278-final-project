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
                    if viewModel.isLoading && viewModel.friendEntries.isEmpty {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Loading feed...")
                                .foregroundColor(.gray)
                                .padding(.top)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.parchment)
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
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.parchment)
                    } else {
                        List(viewModel.friendEntries) { entry in
                            FriendProductivityCard(viewModel: viewModel, entry: entry)
                        }
                        .scrollContentBackground(.hidden)
                        .background(Theme.parchment)
                        .refreshable {
                            await viewModel.refreshFeed()
                        }
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
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(Theme.darkAccentColor)
                VStack(alignment: .leading) {
                    Text(entry.userName)
                        .font(.system(size: 20))
                        .foregroundColor(Theme.darkAccentColor)
                    Text("Updated \(timeAgoString(from: entry.lastUpdated))")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.logoColor)
                }
            }
            
            ProductivityGridPreview(entries: entry.entries)
                .padding(8)
            
            // Comments Section
            if !entry.comments.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(entry.comments, id: \.self) { comment in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "bubble.left.fill")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .foregroundColor(Theme.logoColor)
                            Text(comment)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .padding(.vertical, 2)
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            // Comment input
            if viewModel.showCommentInput[entry.id] ?? false {
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ProductivityGridPreview: View {
    let entries: [ProductivityEntry]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 8)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(0..<24) { hour in
                if let entry = entries.first(where: { $0.timeSlot / 2 == hour }) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(entry.category.color.color)
                        .aspectRatio(1, contentMode: .fit)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }
}

struct FriendProductivityEntry: Identifiable, Codable {
    let id: UUID
    let userId: String
    let username: String
    let date: Date
    let entries: [ProductivityEntry]
    let lastUpdated: Date
    var comments: [String]
    var cheerCount: Int
    
    // For backward compatibility with existing UI
    var userName: String { username }
    
    init(id: UUID = UUID(), userId: String, username: String, date: Date, entries: [ProductivityEntry], lastUpdated: Date, comments: [String] = [], cheerCount: Int = 0) {
        self.id = id
        self.userId = userId
        self.username = username
        self.date = date
        self.entries = entries
        self.lastUpdated = lastUpdated
        self.comments = comments
        self.cheerCount = cheerCount
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
