import SwiftUI
import UserNotifications

struct LockScreenTimerView: View {
    let timeRemaining: TimeInterval
    let totalTime: TimeInterval
    let timerName: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Timer Icon
            Image(systemName: "timer")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.blue)
            
            // Timer Name
            Text(timerName)
                .font(.headline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            // Time Display
            Text(formatTime(timeRemaining))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
            
            // Progress Bar
            ProgressView(value: (totalTime - timeRemaining) / totalTime)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 8)
                .clipShape(Capsule())
            
            // Remaining percentage
            Text("Kalan: %\(Int((timeRemaining / totalTime) * 100))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
        .shadow(radius: 8)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Lock Screen Timer Support
extension LockScreenTimerView {
    static func createPersistentNotification(timerName: String, duration: TimeInterval) {
        // Create an ongoing notification that shows timer status
        let content = UNMutableNotificationContent()
        content.title = "🧘‍♀️ \(timerName)"
        content.body = "Meditasyon devam ediyor - \(formatDuration(duration))"
        content.sound = nil
        content.badge = 1
        content.categoryIdentifier = "MEDITATION_TIMER_ONGOING"
        
        // Use a very short interval to create an immediate notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "meditation-timer-ongoing",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
        
        // Schedule periodic updates every 30 seconds
        schedulePeriodicUpdates(timerName: timerName, duration: duration)
    }
    
    static func schedulePeriodicUpdates(timerName: String, duration: TimeInterval) {
        // Cancel existing updates
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["meditation-timer-update-30", "meditation-timer-update-60", "meditation-timer-update-90"]
        )
        
        // Schedule updates at 30, 60, 90 seconds intervals
        for (_, interval) in [30.0, 60.0, 90.0].enumerated() {
            if interval < duration {
                let remainingTime = duration - interval
                let content = UNMutableNotificationContent()
                content.title = "🧘‍♀️ \(timerName)"
                content.body = "Kalan süre: \(formatDuration(remainingTime))"
                content.sound = nil
                content.badge = 1
                content.categoryIdentifier = "MEDITATION_TIMER_ONGOING"
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "meditation-timer-update-\(Int(interval))",
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    static func updateTimerNotification(timerName: String, remainingTime: TimeInterval) {
        // Remove existing ongoing notification
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: ["meditation-timer-ongoing"]
        )
        
        // Create new notification with updated time
        let content = UNMutableNotificationContent()
        content.title = "🧘‍♀️ \(timerName)"
        content.body = "Kalan süre: \(formatDuration(remainingTime))"
        content.sound = nil
        content.badge = 1
        content.categoryIdentifier = "MEDITATION_TIMER_ONGOING"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "meditation-timer-ongoing",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    static func cancelLiveActivity() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                "meditation-timer-ongoing",
                "meditation-timer-update-30",
                "meditation-timer-update-60", 
                "meditation-timer-update-90",
                "meditation-timer-lockscreen"
            ]
        )
        
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: ["meditation-timer-ongoing"]
        )
        
        // Clear badge
        BadgeManager.clearBadge()
    }
    
    private static func formatDuration(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    LockScreenTimerView(
        timeRemaining: 420,
        totalTime: 600,
        timerName: "Sabah Meditasyonu"
    )
}