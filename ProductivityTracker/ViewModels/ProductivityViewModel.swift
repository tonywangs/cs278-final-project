//
//  ProductivityViewModel.swift
//  ProductivityTracker
//
//  Created by Katie Cheng on 07/05/2025.
//

import Foundation
import UserNotifications
import SwiftUI

class ProductivityViewModel: ObservableObject {
    @Published private(set) var entries: [ProductivityEntry] = []
    private let userDefaults = UserDefaults.standard
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init() {
        loadEntries()
        setupNotifications()
    }
    
    func getActivityType(for timeSlot: Int) -> ActivityCategory {
        if let entry = entries.first(where: { $0.timeSlot == timeSlot }) {
            return entry.category
        }
        return ActivityCategory(name: "Default", color: ColorCodable(color: .gray))
    }
    
    func updateActivity(for timeSlot: Int, activity: ActivityCategory) {
        let entry = ProductivityEntry(
            userId: getCurrentUserId(),
            date: Date(),
            timeSlot: timeSlot,
            category: activity
        )
        
        if let index = entries.firstIndex(where: { $0.timeSlot == timeSlot }) {
            entries[index] = entry
        } else {
            entries.append(entry)
        }
        
        saveEntries()
    }
    
    func shareProductivity() {
        // TODO: Implement sharing functionality
        // This would typically involve:
        // 1. Creating a shareable format of the productivity data
        // 2. Using UIActivityViewController to share
        // 3. Potentially posting to a social feed
    }
    
    private func loadEntries() {
        if let data = userDefaults.data(forKey: "productivityEntries"),
           let decodedEntries = try? JSONDecoder().decode([ProductivityEntry].self, from: data) {
            entries = decodedEntries
        }
    }
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            userDefaults.set(encoded, forKey: "productivityEntries")
        }
    }
    
    private func getCurrentUserId() -> String {
        // TODO: Implement proper user authentication
        return "current_user"
    }
    
    private func setupNotifications() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                self.scheduleDailyReminder()
            }
        }
    }
    
    private func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Complete Your Day"
        content.body = "Don't forget to fill out your productivity grid for today!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 21 // 9 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
}
