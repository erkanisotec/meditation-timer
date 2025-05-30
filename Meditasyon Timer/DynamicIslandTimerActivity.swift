import Foundation
import UserNotifications

// MARK: - Enhanced Notification Manager for Lock Screen Visibility
class EnhancedNotificationManager {
    static let shared = EnhancedNotificationManager()
    private var timerStartTime: Date?
    private var totalDuration: TimeInterval = 0
    private var timerName: String = ""
    private var updateTimer: Timer?
    
    private init() {}
    
    func startTimerNotifications(timerName: String, duration: TimeInterval) {
        self.timerName = timerName
        self.totalDuration = duration
        self.timerStartTime = Date()
        
        // Create initial persistent notification
        createPersistentTimerNotification()
        
        // Start periodic updates every 30 seconds
        startPeriodicUpdates()
    }
    
    func stopTimerNotifications() {
        updateTimer?.invalidate()
        updateTimer = nil
        
        // Remove all timer notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: getTimerNotificationIdentifiers()
        )
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: getTimerNotificationIdentifiers()
        )
        
        BadgeManager.clearBadge()
    }
    
    private func createPersistentTimerNotification() {
        guard let startTime = timerStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = max(0, totalDuration - elapsed)
        
        let content = UNMutableNotificationContent()
        content.title = "🧘‍♀️ \(timerName)"
        content.body = "Kalan: \(formatTime(remaining)) | %\(Int(((totalDuration - remaining) / totalDuration) * 100)) tamamlandı"
        content.sound = nil
        content.badge = 1
        content.categoryIdentifier = "MEDITATION_TIMER_ONGOING"
        
        // Create immediate notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "timer-persistent-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func startPeriodicUpdates() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updateTimerNotification()
        }
    }
    
    private func updateTimerNotification() {
        guard let startTime = timerStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = max(0, totalDuration - elapsed)
        
        if remaining <= 0 {
            stopTimerNotifications()
            return
        }
        
        // Remove old notification
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: getTimerNotificationIdentifiers()
        )
        
        // Create updated notification
        createPersistentTimerNotification()
    }
    
    private func getTimerNotificationIdentifiers() -> [String] {
        return [
            "timer-persistent",
            "meditation-timer-ongoing",
            "meditation-timer-update"
        ]
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Simplified Live Activity Manager (Fallback)
class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private init() {}
    
    func startLiveActivity(timerName: String, duration: TimeInterval) {
        // Use enhanced notifications as fallback for now
        EnhancedNotificationManager.shared.startTimerNotifications(
            timerName: timerName,
            duration: duration
        )
        
        print("Timer notifications started for lock screen visibility")
    }
    
    func updateLiveActivity(remainingTime: TimeInterval, progress: Double, timerName: String) {
        // Updates are handled automatically by the enhanced notification manager
    }
    
    func endLiveActivity() {
        EnhancedNotificationManager.shared.stopTimerNotifications()
        print("Timer notifications stopped")
    }
}