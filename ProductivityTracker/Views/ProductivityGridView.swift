//
//  ProductivityGridView.swift
//  ProductivityTracker
//
//  Created by Katie Cheng on 07/05/2025.
//

import SwiftUI

struct ProductivityGridView: View {
    let hourglassPattern = [5, 4, 3, 0, 3, 4, 5]
    let totalHours = 24
    let gridBoxSize: CGFloat = 40

    @State private var selectedActivity: ActivityType = .sleep
    @State private var hourActivities: [ActivityType?] = Array(repeating: nil, count: 24)

    var body: some View {
        VStack(spacing: 0) {
            // Palette caption
            Text("Color in your day:")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.top, 24)
                .padding(.bottom, 2)
            // Palette at the top
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 4) {
                    HStack(spacing: 16) {
                        ForEach(ActivityType.allCases, id: \ .self) { activity in
                            Button(action: { selectedActivity = activity }) {
                                Circle()
                                    .fill(activity.color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedActivity == activity ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .frame(width: 60)
                        }
                    }
                    HStack(spacing: 16) {
                        ForEach(ActivityType.allCases, id: \ .self) { activity in
                            Text(activity.rawValue.capitalized)
                                .font(.caption2)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .frame(width: 60)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 8)
            }

            Text("Today's Hourglass")
                .font(.system(size: 28))
                .bold()
                .foregroundColor(Theme.darkAccentColor)
                .padding(.top, 30)
                .frame(maxWidth: .infinity, alignment: .center)

            // Precompute the hour indices for each row
            let hourglassGrid: [[Int?]] = {
                var result: [[Int?]] = []
                var hour = 0
                for count in hourglassPattern {
                    if count == 0 {
                        result.append([nil])
                    } else {
                        result.append((0..<count).map { _ in let h = hour; hour += 1; return h })
                    }
                }
                return result
            }()
            VStack(spacing: 32) {
                ForEach(0..<hourglassGrid.count, id: \ .self) { row in
                    HStack(spacing: 12) {
                        Spacer(minLength: 0)
                        ForEach(hourglassGrid[row], id: \ .self) { hourOpt in
                            if let hour = hourOpt {
                                ZStack {
                                    let isBlack = hourActivities[hour]?.color == .black
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill((hourActivities[hour]?.color ?? ActivityType.other.color).opacity(0.8))
                                        .frame(width: gridBoxSize, height: gridBoxSize)
                                        .onTapGesture {
                                            hourActivities[hour] = selectedActivity
                                        }
                                    // Format hour as 12-hour with AM/PM
                                    let hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
                                    let ampm = hour < 12 ? "AM" : "PM"
                                    Text("\(hour12)\(ampm)")
                                        .font(.caption)
                                        .foregroundColor(isBlack ? Theme.parchment : .primary)
                                }
                            } else if row == 3 { // Center row, center symbol
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.clear)
                                        .frame(width: gridBoxSize, height: gridBoxSize)
                                    Image(systemName: "hourglass")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: gridBoxSize * 0.7, height: gridBoxSize * 0.7)
                                        .foregroundColor(Theme.logoColor)
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.clear)
                                    .frame(width: gridBoxSize, height: gridBoxSize)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.vertical, 24)
            Spacer()
        }
        .background(Theme.parchment.ignoresSafeArea())
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
