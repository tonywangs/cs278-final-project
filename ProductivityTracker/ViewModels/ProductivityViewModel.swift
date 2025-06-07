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
    private var currentUserId: String?
    
    init() {
        setupNotifications()
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let newUserId = user?.uid {
                    // Check if user changed
                    if self?.currentUserId != newUserId {
                        print("User changed from \(self?.currentUserId ?? "none") to \(newUserId)")
                        self?.currentUserId = newUserId
                        
                        // Clear old data and load new user's data
                        self?.clearEntries()
                        await self?.loadEntriesFromFirebase()
                    }
                } else {
                    // User logged out
                    print("User logged out")
                    self?.currentUserId = nil
                    self?.clearEntries()
                }
            }
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
    
    private func clearEntries() {
        entries = []
        print("Cleared hourglass entries")
    }
    
    private func getUserSpecificKey() -> String {
        guard let userId = currentUserId else {
            return "productivityEntries_anonymous"
        }
        return "productivityEntries_\(userId)"
    }
    
    private func loadEntries() {
        let key = getUserSpecificKey()
        if let data = userDefaults.data(forKey: key),
           let decodedEntries = try? JSONDecoder().decode([ProductivityEntry].self, from: data) {
            // Only load entries for current user and today's date
            let today = Calendar.current.startOfDay(for: Date())
            let filteredEntries = decodedEntries.filter { 
                Calendar.current.isDate($0.date, inSameDayAs: today) && 
                $0.userId == (currentUserId ?? "anonymous")
            }
            entries = filteredEntries
            print("Loaded \(filteredEntries.count) entries from local storage for user \(currentUserId ?? "anonymous")")
        } else {
            entries = []
            print("No local entries found for user \(currentUserId ?? "anonymous"), starting with blank hourglass")
        }
    }
    
    func refreshFromFirebase() async {
        await loadEntriesFromFirebase()
    }
    
    func loadEntriesFromFirebase() async {
        guard let currentUser = Auth.auth().currentUser else {
            // If not authenticated, start with blank hourglass
            await MainActor.run {
                self.clearEntries()
                print("No authenticated user, starting with blank hourglass")
            }
            return
        }
        
        // Update current user ID if needed
        await MainActor.run {
            if self.currentUserId != currentUser.uid {
                self.currentUserId = currentUser.uid
            }
        }
        
        let db = Firestore.firestore()
        
        // Get today's date string
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayStr = formatter.string(from: today)
        let docId = "\(currentUser.uid)_\(todayStr)"
        
        print("Loading hourglass data for user \(currentUser.uid) on \(todayStr)")
        
        do {
            let document = try await db.collection("productivity").document(docId).getDocument()
            
            if document.exists,
               let data = document.data(),
               let hourglassData = data["hourglassData"] as? [String: [String: Any]] {
                
                print("Found Firebase data with \(hourglassData.count) hours")
                
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
                    print("Loaded \(firebaseEntries.count) entries from Firebase for user \(currentUser.uid)")
                    // Save to user-specific local storage as backup
                    self.saveEntries()
                }
                
            } else {
                // No Firebase data found for today, start with blank hourglass
                print("No Firebase data found for today for user \(currentUser.uid), starting with blank hourglass")
                await MainActor.run {
                    self.entries = []
                    // Clear any stale local data for this user/date
                    self.saveEntries()
                }
            }
            
        } catch {
            print("Failed to load from Firebase: \(error)")
            // On error, start with blank hourglass for this user rather than loading potentially stale data
            await MainActor.run {
                self.entries = []
                print("Started with blank hourglass due to Firebase error")
            }
        }
    }
    
    private func saveEntries() {
        let key = getUserSpecificKey()
        if let encoded = try? JSONEncoder().encode(entries) {
            userDefaults.set(encoded, forKey: key)
            print("Saved \(entries.count) entries to local storage with key: \(key)")
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
            
            // Notify that hourglass data has been updated
            NotificationCenter.default.post(name: NSNotification.Name("HourglassDataUpdated"), object: nil)
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
