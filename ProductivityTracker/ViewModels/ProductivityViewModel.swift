//
//  ProductivityViewModel.swift
//  ProductivityTracker
//
//  Created by Katie Cheng on 07/05/2025.
//

import Foundation
import UserNotifications
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class ProductivityViewModel: ObservableObject {
    @Published private(set) var entries: [ProductivityEntry] = []
    private let userDefaults = UserDefaults.standard
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init() {
        setupNotifications()
        // Load from Firebase first, then fall back to local storage
        Task {
            await loadEntriesFromFirebase()
        }
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
        
        // Also sync to server
        Task {
            await syncHourglassData()
        }
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
    
    func refreshFromFirebase() async {
        await loadEntriesFromFirebase()
    }
    
    func loadEntriesFromFirebase() async {
        guard let currentUser = Auth.auth().currentUser else {
            // If not authenticated, load from local storage
            await MainActor.run {
                loadEntries()
            }
            return
        }
        
        let db = Firestore.firestore()
        
        // Get today's date string
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: today)
        let docId = "\(currentUser.uid)_\(todayStr)"
        
        do {
            let document = try await db.collection("productivity").document(docId).getDocument()
            
            if document.exists,
               let data = document.data(),
               let hourglassData = data["hourglassData"] as? [String: [String: Any]] {
                
                // Convert Firebase data back to entries
                var firebaseEntries: [ProductivityEntry] = []
                
                for (hourStr, activityData) in hourglassData {
                    guard let hour = Int(hourStr),
                          let activityName = activityData["name"] as? String,
                          let colorData = activityData["color"] as? [String: Double] else {
                        continue
                    }
                    
                    let activityColor = ColorCodable(
                        red: colorData["red"] ?? 0,
                        green: colorData["green"] ?? 0,
                        blue: colorData["blue"] ?? 0,
                        opacity: colorData["opacity"] ?? 1
                    )
                    
                    let activity = ActivityCategory(
                        name: activityName,
                        color: activityColor
                    )
                    
                    // Create entries for both 30-minute slots in this hour
                    firebaseEntries.append(ProductivityEntry(
                        userId: currentUser.uid,
                        date: today,
                        timeSlot: hour * 2,
                        category: activity
                    ))
                    firebaseEntries.append(ProductivityEntry(
                        userId: currentUser.uid,
                        date: today,
                        timeSlot: hour * 2 + 1,
                        category: activity
                    ))
                }
                
                await MainActor.run {
                    self.entries = firebaseEntries
                    print("Loaded \(firebaseEntries.count) entries from Firebase")
                    // Also save to local storage as backup
                    self.saveEntries()
                }
                
            } else {
                // No Firebase data found, load from local storage
                print("No Firebase data found for today, loading from local storage")
                await MainActor.run {
                    loadEntries()
                }
            }
            
        } catch {
            print("Failed to load from Firebase: \(error), falling back to local storage")
            await MainActor.run {
                loadEntries()
            }
        }
    }
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            userDefaults.set(encoded, forKey: "productivityEntries")
        }
    }
    
    private func getCurrentUserId() -> String {
        return Auth.auth().currentUser?.uid ?? "anonymous"
    }
    
    private func getCurrentUsername() -> String {
        // We'll need to get this from the user profile
        // For now, return a placeholder
        return "unknown_user"
    }
    
    func syncHourglassData() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        // Get username from Firestore
        let db = Firestore.firestore()
        
        do {
            let userDoc = try await db.collection("users").document(currentUser.uid).getDocument()
            let username = userDoc.data()?["username"] as? String ?? "Unknown"
            
            // Convert entries to hourglass format (hour -> activity mapping)
            var hourglassData: [String: [String: Any]] = [:]
            
            for entry in entries {
                let hour = entry.timeSlot / 2 // Convert 30-min slots to hours
                let hourStr = String(hour)
                
                hourglassData[hourStr] = [
                    "name": entry.category.name,
                    "color": [
                        "red": entry.category.color.red,
                        "green": entry.category.color.green,
                        "blue": entry.category.color.blue,
                        "opacity": entry.category.color.opacity
                    ]
                ]
            }
            
            // Save to Firestore with date-based document ID
            let today = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let todayStr = formatter.string(from: today)
            let docId = "\(currentUser.uid)_\(todayStr)"
            
            try await db.collection("productivity").document(docId).setData([
                "userId": currentUser.uid,
                "username": username,
                "date": today,
                "hourglassData": hourglassData,
                "lastUpdated": FieldValue.serverTimestamp(),
                "visibility": "followers"
            ], merge: true)
            
            print("Hourglass data synced successfully")
        } catch {
            print("Failed to sync hourglass data: \(error)")
        }
    }
    
    private func setupNotifications() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                self.scheduleDailyReminder()
            }
        }
    }
    
    private func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Reminder"
        content.body = "Remember to enter your hours for today if you haven't already!"
        content.sound = .default
        content.userInfo = ["openApp": true]
        
        var dateComponents = DateComponents()
        dateComponents.hour = 21 // 9 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}
