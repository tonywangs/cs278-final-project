//
//  ProductivityEntry.swift
//  ProductivityTracker
//
//  Created by Katie Cheng on 07/05/2025.
//

import Foundation
import SwiftUI

enum ActivityType: String, Codable, CaseIterable {
    case sleep = "sleep"
    case socialMedia = "social media"
    case meals = "meals"
    case homework = "homework"
    case classes = "classes"
    case social = "social"
    case exercise = "exercise"
    case routine = "morn/night routine"
    case aquaProductivity = "other productive"
    case other = "other"
    
    var color: Color {
        switch self {
        case .sleep: return .black
        case .socialMedia: return .red
        case .meals: return .yellow
        case .homework: return .green
        case .classes: return Color(red: 0, green: 0.4, blue: 0) // dark green
        case .social: return .pink
        case .exercise: return Color(red: 0.0, green: 0.5, blue: 1.0) // bright blue
        case .routine: return .gray
        case .aquaProductivity: return Color(red: 0.0, green: 0.9, blue: 0.9) // aqua
        case .other: return Color(.systemGray4)
        }
    }
}

struct ProductivityEntry: Identifiable, Codable {
    let id: UUID
    let userId: String
    let date: Date
    let timeSlot: Int // 0-47 representing 30-minute slots in a 24-hour day
    let activityType: ActivityType
    let notes: String?
    
    init(id: UUID = UUID(), userId: String, date: Date, timeSlot: Int, activityType: ActivityType, notes: String? = nil) {
        self.id = id
        self.userId = userId
        self.date = date
        self.timeSlot = timeSlot
        self.activityType = activityType
        self.notes = notes
    }
}
