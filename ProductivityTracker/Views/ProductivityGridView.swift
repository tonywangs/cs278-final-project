//
//  ProductivityGridView.swift
//  ProductivityTracker
//
//  Created by Katie Cheng on 07/05/2025.
//

import SwiftUI

struct ActivityButton: View {
    let activity: ActivityCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(activity.color.color)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 3)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 60)
    }
}

struct ActivityLabel: View {
    let activity: ActivityCategory
    
    var body: some View {
        Text(activity.name.capitalized)
            .font(.caption2)
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
            .frame(width: 60)
    }
}

struct ActivityPalette: View {
    let selectedActivity: ActivityCategory
    let activities: [ActivityCategory]
    let onSelect: (ActivityCategory) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(spacing: 4) {
                HStack(spacing: 16) {
                    ForEach(activities, id: \.self) { activity in
                        ActivityButton(activity: activity, isSelected: selectedActivity == activity) {
                            onSelect(activity)
                        }
                    }
                }
                HStack(spacing: 16) {
                    ForEach(activities, id: \.self) { activity in
                        ActivityLabel(activity: activity)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }
}

struct HourglassRow: View {
    let row: [Int?]
    let hourActivities: [ActivityCategory?]
    let selectedActivity: ActivityCategory
    let gridBoxSize: CGFloat
    let onHourTap: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Spacer(minLength: 0)
            ForEach(Array(row.enumerated()), id: \.offset) { _, hourOpt in
                if let hour = hourOpt {
                    ZStack {
                        let isBlack = hourActivities[hour]?.color.color == .black
                        let fillColor = hourActivities[hour]?.color.color ?? ActivityCategory(
                            name: "Other",
                            color: ColorCodable(color: .gray)
                        ).color.color
                        RoundedRectangle(cornerRadius: 8)
                            .fill(fillColor.opacity(0.8))
                            .frame(width: gridBoxSize, height: gridBoxSize)
                            .onTapGesture {
                                onHourTap(hour)
                            }
                        // Format hour as 12-hour with AM/PM
                        let hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
                        let ampm = hour < 12 ? "AM" : "PM"
                        Text("\(hour12)\(ampm)")
                            .font(.caption)
                            .foregroundColor(isBlack ? Theme.parchment : .primary)
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

struct ProductivityGridView: View {
    let hourglassPattern = [5, 4, 3, 0, 3, 4, 5]
    let totalHours = 24
    let gridBoxSize: CGFloat = 40

    @State private var selectedActivity: ActivityCategory = ActivityCategory(
        name: "Default",
        color: ColorCodable(color: .gray)
    )
    @State private var hourActivities: [ActivityCategory?] = Array(repeating: nil, count: 24)
    @State private var showingActivityManagement = false
    @State private var activities: [ActivityCategory] = []

    var hourglassGrid: [[Int?]] {
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
    }

    var body: some View {
        VStack(spacing: 0) {
            // Palette caption
            HStack {
                Text("Color in your day:")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { showingActivityManagement = true }) {
                    Image(systemName: "gear")
                        .foregroundColor(.primary)
                }
            }
            .padding(.top, 24)
            .padding(.horizontal)
            .padding(.bottom, 2)
            
            // Palette at the top
            ActivityPalette(
                selectedActivity: selectedActivity,
                activities: activities,
                onSelect: { activity in
                    selectedActivity = activity
                }
            )

            Text("Today's Hourglass")
                .font(.system(size: 28))
                .bold()
                .foregroundColor(Theme.darkAccentColor)
                .padding(.top, 30)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(spacing: 32) {
                ForEach(Array(hourglassGrid.enumerated()), id: \.offset) { index, row in
                    HourglassRow(
                        row: row,
                        hourActivities: hourActivities,
                        selectedActivity: selectedActivity,
                        gridBoxSize: gridBoxSize,
                        onHourTap: { hour in
                            hourActivities[hour] = selectedActivity
                        }
                    )
                }
            }
            .padding(.vertical, 24)
            Spacer()
        }
        .background(Theme.parchment.ignoresSafeArea())
        .sheet(isPresented: $showingActivityManagement) {
            ActivityManagementView()
        }
        .onAppear {
            loadActivities()
            setupNotificationObserver()
        }
        .onChange(of: showingActivityManagement) { newValue in
            if !newValue {
                loadActivities()
            }
        }
    }
    
    private func loadActivities() {
        activities = ActivityCategory.allCases
    }
    
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ActivitiesDidChange"),
            object: nil,
            queue: .main
        ) { _ in
            loadActivities()
        }
    }
}

struct TimeSlotView: View {
    let timeSlot: Int
    let activityType: ActivityCategory
    let isSelected: Bool
    
    var body: some View {
        Rectangle()
            .fill(activityType.color.color)
            .frame(height: 30)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
    }
}

struct ActivityPickerView: View {
    let selectedActivity: ActivityCategory
    let onSelect: (ActivityCategory) -> Void
    
    var body: some View {
        NavigationView {
            List(ActivityCategory.allCases, id: \.self) { activity in
                Button(action: {
                    onSelect(activity)
                }) {
                    HStack {
                        Circle()
                            .fill(activity.color.color)
                            .frame(width: 20, height: 20)
                        Text(activity.name.capitalized)
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
