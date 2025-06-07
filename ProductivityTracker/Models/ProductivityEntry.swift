//
//  ProductivityEntry.swift
//  ProductivityTracker
//
//  Created by Katie Cheng on 07/05/2025.
//

import Foundation
import SwiftUI
import FirebaseAuth

struct ActivityCategory: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let color: ColorCodable
    let isDefault: Bool // Track if this is a default activity
    
    init(id: UUID = UUID(), name: String, color: ColorCodable, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.color = color
        self.isDefault = isDefault
    }
    
    static func == (lhs: ActivityCategory, rhs: ActivityCategory) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static var allCases: [ActivityCategory] {
        // Get user-specific key for activities
        let userKey = getUserSpecificKey()
        
        if let data = UserDefaults.standard.data(forKey: userKey),
           let savedActivities = try? JSONDecoder().decode([ActivityCategory].self, from: data) {
            
            // Ensure default activities are properly marked and present
            var activities = savedActivities
            let defaultNames = Set(defaultActivities.map { $0.name.lowercased() })
            
            // Update any activities that match default names to have isDefault = true
            for i in activities.indices {
                if defaultNames.contains(activities[i].name.lowercased()) {
                    activities[i] = ActivityCategory(
                        id: activities[i].id,
                        name: activities[i].name,
                        color: activities[i].color,
                        isDefault: true
                    )
                }
            }
            
            // Add any missing default activities
            for defaultActivity in defaultActivities {
                if !activities.contains(where: { $0.name.lowercased() == defaultActivity.name.lowercased() }) {
                    activities.append(defaultActivity)
                }
            }
            
            // Save the corrected activities
            if let encoded = try? JSONEncoder().encode(activities) {
                UserDefaults.standard.set(encoded, forKey: userKey)
            }
            
            return activities
        }
        
        // If no saved activities, create and save default activities for this user
        let defaults = defaultActivities
        if let encoded = try? JSONEncoder().encode(defaults) {
            UserDefaults.standard.set(encoded, forKey: userKey)
        }
        return defaults
    }
    
    private static func getUserSpecificKey() -> String {
        if let currentUser = Auth.auth().currentUser {
            return "savedActivities_\(currentUser.uid)"
        }
        return "savedActivities_anonymous"
    }
    
    static func saveActivities(_ activities: [ActivityCategory]) {
        let userKey = getUserSpecificKey()
        if let encoded = try? JSONEncoder().encode(activities) {
            UserDefaults.standard.set(encoded, forKey: userKey)
            print("Saved \(activities.count) activities for user key: \(userKey)")
        }
    }
    
    private static let defaultActivities: [ActivityCategory] = [
        ActivityCategory(name: "Sleep", color: ColorCodable(color: .black), isDefault: true),
        ActivityCategory(name: "Study", color: ColorCodable(color: .blue), isDefault: true),
        ActivityCategory(name: "Exercise", color: ColorCodable(color: .orange), isDefault: true),
        ActivityCategory(name: "Social", color: ColorCodable(color: .red), isDefault: true),
        ActivityCategory(name: "Work", color: ColorCodable(color: .green), isDefault: true)
    ]
    
    // Helper to get default color for activity name
    static func getDefaultColor(for activityName: String) -> Color {
        let lowercaseName = activityName.lowercased()
        switch lowercaseName {
        case "sleep":
            return .black
        case "study":
            return .blue
        case "exercise":
            return .orange
        case "social":
            return .red
        case "work":
            return .green
        default:
            return .gray
        }
    }
}

// Codable wrapper for SwiftUI Color
struct ColorCodable: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double
    
    init(color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
    }
    
    // Additional initializer for direct RGBA values
    init(red: Double, green: Double, blue: Double, opacity: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

struct ProductivityEntry: Identifiable, Codable {
    let id: UUID
    let userId: String
    let date: Date
    let timeSlot: Int // 0-47 representing 30-minute slots in a 24-hour day
    let category: ActivityCategory
    let notes: String?
    
    init(id: UUID = UUID(), userId: String, date: Date, timeSlot: Int, category: ActivityCategory, notes: String? = nil) {
        self.id = id
        self.userId = userId
        self.date = date
        self.timeSlot = timeSlot
        self.category = category
        self.notes = notes
    }
}
