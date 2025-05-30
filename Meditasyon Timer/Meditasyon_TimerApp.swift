//
//  Meditasyon_TimerApp.swift
//  Meditasyon Timer
//
//  Created by Erkan Öztürk on 16.02.2025.
//

import SwiftUI
import UserNotifications

@main
struct Meditasyon_TimerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Clear badge on app start
                    BadgeManager.clearBadge()
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Clear badge on app launch
        BadgeManager.clearBadge()
        
        return true
    }
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // For ongoing timer notifications, show them silently
        if notification.request.content.categoryIdentifier == "MEDITATION_TIMER_ONGOING" {
            completionHandler([.banner])
        } else {
            completionHandler([.banner, .sound])
        }
    }
    
    // Handle notification actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Clear badge when user interacts with notification
        BadgeManager.clearBadge()
        completionHandler()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear badge when app becomes active
        BadgeManager.clearBadge()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
