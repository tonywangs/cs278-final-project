//
//  ProductivityGridView.swift
//  ProductivityTracker
//
//  Created by Katie Cheng on 07/05/2025.
//

import SwiftUI

struct ProductivityGridView: View {
    let hours = Array(0..<24)
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack {
            Text("Today's Productivity")
                .font(.title)
                .bold()
                .padding(.top)
            Spacer()
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(hours, id: \.self) { hour in
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.15))
                            .aspectRatio(1, contentMode: .fit)
                        Text(String(format: "%02d:00", hour))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding()
            Spacer()
        }
        .background(Color(.systemBackground))
    }
}

struct TimeSlotView: View {
    let timeSlot: Int
    let activityType: ActivityType
    let isSelected: Bool
    
    var body: some View {
        Rectangle()
            .fill(Color(activityType.color))
            .frame(height: 30)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
    }
}

struct ActivityPickerView: View {
    let selectedActivity: ActivityType
    let onSelect: (ActivityType) -> Void
    
    var body: some View {
        NavigationView {
            List(ActivityType.allCases, id: \.self) { activity in
                Button(action: {
                    onSelect(activity)
                }) {
                    HStack {
                        Circle()
                            .fill(Color(activity.color))
                            .frame(width: 20, height: 20)
                        Text(activity.rawValue.capitalized)
                        Spacer()
                        if activity == selectedActivity {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("Select Activity")
        }
    }
}

struct ProductivityGridView_Previews: PreviewProvider {
    static var previews: some View {
        ProductivityGridView()
    }
}
