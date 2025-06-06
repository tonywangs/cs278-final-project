//
//  ProductivityEntry.swift
//  ProductivityTracker
//
//  Created by Katie Cheng on 07/05/2025.
//

import Foundation
import SwiftUI

struct ActivityCategory: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let color: ColorCodable
    
    init(id: UUID = UUID(), name: String, color: ColorCodable) {
        self.id = id
        self.name = name
        self.color = color
    }
    
    static func == (lhs: ActivityCategory, rhs: ActivityCategory) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static var allCases: [ActivityCategory] {
        if let data = UserDefaults.standard.data(forKey: "savedActivities"),
           let savedActivities = try? JSONDecoder().decode([ActivityCategory].self, from: data) {
            return savedActivities
        }
        // If no saved activities, create and save default activities
        let defaults = defaultActivities
        if let encoded = try? JSONEncoder().encode(defaults) {
            UserDefaults.standard.set(encoded, forKey: "savedActivities")
        }
        return defaults
    }
    
    private static let defaultActivities: [ActivityCategory] = [
        ActivityCategory(name: "Homework", color: ColorCodable(color: .green)),
        ActivityCategory(name: "Study", color: ColorCodable(color: .blue)),
        ActivityCategory(name: "Exercise", color: ColorCodable(color: .orange)),
        ActivityCategory(name: "Sleep", color: ColorCodable(color: .purple)),
        ActivityCategory(name: "Social", color: ColorCodable(color: .pink))
    ]
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
