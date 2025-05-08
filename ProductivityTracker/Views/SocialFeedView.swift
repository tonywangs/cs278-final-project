//
//  SocialFeedView.swift
//  ProductivityTracker
//
//  Created by Katie Cheng on 07/05/2025.
//

import SwiftUI

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
                    List(viewModel.friendEntries) { entry in
                        FriendProductivityCard(viewModel: viewModel, entry: entry)
                    }
                    .scrollContentBackground(.hidden)
                    .background(Theme.parchment)
                    .refreshable {
                        await viewModel.refreshFeed()
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
                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
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
                        .fill(entry.activityType.color)
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

struct FriendProductivityEntry: Identifiable {
    let id: UUID
    let userId: String
    let userName: String
    let date: Date
    let entries: [ProductivityEntry]
    var comments: [String]
    var cheerCount: Int
}

class SocialFeedViewModel: ObservableObject {
    @Published var friendEntries: [FriendProductivityEntry] = []
    @Published var commentInputs: [UUID: String] = [:]
    @Published var showCommentInput: [UUID: Bool] = [:]
    @Published var cheeredPosts: Set<UUID> = []
    
    init() {
        // TODO: Implement proper data fetching
        loadMockData()
    }
    
    func refreshFeed() async {
        // TODO: Implement proper data refresh
        await MainActor.run {
            loadMockData()
        }
    }
    
    func addComment(_ comment: String, to entry: FriendProductivityEntry) {
        guard let idx = friendEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        friendEntries[idx].comments.append(comment)
        commentInputs[entry.id] = ""
        showCommentInput[entry.id] = false
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
    
    private func generateMockEntries() -> [ProductivityEntry] {
        var entries: [ProductivityEntry] = []
        
        // Helper function to get a random activity based on time of day and user type
        func getActivityForHour(_ hour: Int, userType: UserType) -> ActivityType {
            switch userType {
            case .student:
                switch hour {
                case 0...6:  // Night
                    return .sleep
                case 7...8:  // Morning
                    return [.meals, .socialMedia].randomElement()!
                case 9...11: // Late morning
                    return [.classes, .homework].randomElement()!
                case 12...13: // Lunch
                    return .meals
                case 14...16: // Afternoon
                    return [.classes, .homework, .socialMedia].randomElement()!
                case 17...18: // Early evening
                    return [.meals, .social, .homework].randomElement()!
                case 19...21: // Evening
                    return [.social, .homework, .socialMedia].randomElement()!
                case 22...23: // Late night
                    return [.socialMedia, .sleep].randomElement()!
                default:
                    return .sleep
                }
            case .professional:
                switch hour {
                case 0...6:  // Night
                    return .sleep
                case 7...8:  // Morning
                    return [.meals, .socialMedia].randomElement()!
                case 9...17: // Work hours
                    return [.homework, .classes].randomElement()! // Using homework/classes to represent work
                case 18...19: // Evening
                    return [.meals, .social].randomElement()!
                case 20...23: // Night
                    return [.social, .socialMedia, .sleep].randomElement()!
                default:
                    return .sleep
                }
            }
        }
        
        // Helper function to create activity streaks
        func createActivityStreak(startHour: Int, duration: Int, activity: ActivityType) {
            for slot in (startHour * 2)..<(startHour * 2 + duration * 2) {
                if slot < 48 {
                    entries.append(ProductivityEntry(
                        userId: "current_user",
                        date: Date(),
                        timeSlot: slot,
                        activityType: activity
                    ))
                }
            }
        }
        
        // Generate entries for each 30-minute slot
        for slot in 0..<48 {
            let hour = slot / 2
            let activity = getActivityForHour(hour, userType: .student)
            entries.append(ProductivityEntry(
                userId: "current_user",
                date: Date(),
                timeSlot: slot,
                activityType: activity
            ))
        }
        return entries
    }
    
    enum UserType {
        case student
        case professional
    }
    
    private func loadMockData() {
        // Mock data for demonstration
        let mockEntries = [
            FriendProductivityEntry(
                id: UUID(),
                userId: "user1",
                userName: "Tony Wang",
                date: Date(),
                entries: generateMockEntries(),
                comments: ["This is so colorful! Love your routine."],
                cheerCount: 2
            ),
            FriendProductivityEntry(
                id: UUID(),
                userId: "user2",
                userName: "Sheryl Chen",
                date: Date().addingTimeInterval(-86400), // Yesterday
                entries: generateMockEntries(),
                comments: [],
                cheerCount: 0
            ),
            FriendProductivityEntry(
                id: UUID(),
                userId: "user3",
                userName: "Katie Cheng",
                date: Date().addingTimeInterval(-172800), // Two days ago
                entries: generateMockEntries(),
                comments: [],
                cheerCount: 1
            ),
            FriendProductivityEntry(
                id: UUID(),
                userId: "user4",
                userName: "Allan Guo",
                date: Date().addingTimeInterval(-604800), // Last week
                entries: generateMockEntries(),
                comments: [],
                cheerCount: 0
            ),
            FriendProductivityEntry(
                id: UUID(),
                userId: "user5",
                userName: "Aarav Wattal",
                date: Date().addingTimeInterval(-1209600), // Two weeks ago
                entries: generateMockEntries(),
                comments: [],
                cheerCount: 0
            )
        ]
        
        friendEntries = mockEntries
    }
}

#Preview {
    SocialFeedView()
}
