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
        NavigationView {
            List(viewModel.friendEntries) { entry in
                FriendProductivityCard(entry: entry)
            }
            .navigationTitle("Friends' Productivity")
            .refreshable {
                await viewModel.refreshFeed()
            }
        }
    }
}

struct FriendProductivityCard: View {
    let entry: FriendProductivityEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading) {
                    Text(entry.userName)
                        .font(.headline)
                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            ProductivityGridPreview(entries: entry.entries)
            
            HStack {
                Button(action: {}) {
                    Label("Like", systemImage: "heart")
                }
                Spacer()
                Button(action: {}) {
                    Label("Comment", systemImage: "message")
                }
            }
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ProductivityGridPreview: View {
    let entries: [ProductivityEntry]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 12)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 1) {
            ForEach(0..<48) { slot in
                if let entry = entries.first(where: { $0.timeSlot == slot }) {
                    Rectangle()
                        .fill(Color(entry.activityType.color))
                        .frame(height: 20)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 20)
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
}

class SocialFeedViewModel: ObservableObject {
    @Published var friendEntries: [FriendProductivityEntry] = []
    
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
    
    private func loadMockData() {
        // Mock data for demonstration
        let mockEntries = [
            FriendProductivityEntry(
                id: UUID(),
                userId: "user1",
                userName: "John Doe",
                date: Date(),
                entries: generateMockEntries()
            ),
            FriendProductivityEntry(
                id: UUID(),
                userId: "user2",
                userName: "Jane Smith",
                date: Date(),
                entries: generateMockEntries()
            )
        ]
        
        friendEntries = mockEntries
    }
    
    private func generateMockEntries() -> [ProductivityEntry] {
        var entries: [ProductivityEntry] = []
        for slot in 0..<48 {
            let activityType: ActivityType = [.sleep, .productive, .exercise, .leisure, .other].randomElement()!
            entries.append(ProductivityEntry(
                userId: "current_user",
                date: Date(),
                timeSlot: slot,
                activityType: activityType
            ))
        }
        return entries
    }
}

#Preview {
    SocialFeedView()
}
