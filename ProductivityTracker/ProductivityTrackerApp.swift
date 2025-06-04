//
//  ProductivityTrackerApp.swift
//  ProductivityTracker
//
//  Created by Katie Cheng on 07/05/2025.
//

import SwiftUI
import FirebaseCore
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle the notification tap
        if response.notification.request.content.userInfo["openApp"] as? Bool == true {
            // The app will automatically come to foreground when notification is tapped
            // You can add additional navigation logic here if needed
        }
        
        completionHandler()
    }
}

@main
struct ProductivityTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .accentColor(Theme.logoColor)
        }
    }
}
