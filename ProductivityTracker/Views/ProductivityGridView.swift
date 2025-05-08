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
        VStack(alignment: .leading, spacing: 0) {
            
            Text("Today's Hourglass")
                .font(.system(size: 28))
                .bold()
                .foregroundColor(Theme.darkAccentColor)
                .padding(.top, 40)
                .frame(maxWidth: .infinity, alignment: .center)
            Spacer()
            let hourglassPattern = [5, 4, 3, 0, 3, 4, 5]
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
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Text(String(format: "%02d:00", hour))
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.clear)
                                    .frame(width: 40, height: 40)
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
