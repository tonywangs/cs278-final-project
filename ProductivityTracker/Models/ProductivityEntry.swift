//
//  ProductivityEntry.swift
//  ProductivityTracker
//
//  Created by Katie Cheng on 07/05/2025.
//

import Foundation

enum ActivityType: String, Codable, CaseIterable {
    case sleep = "sleep"
    case productive = "productive"
    case exercise = "exercise"
    case leisure = "leisure"
    case other = "other"
    
    var color: String {
        switch self {
        case .sleep: return "black"
        case .productive: return "blue"
        case .exercise: return "red"
        case .leisure: return "green"
        case .other: return "gray"
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
