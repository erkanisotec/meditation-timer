import Foundation
import SwiftUI
import UserNotifications

class BackgroundTimerManager: ObservableObject {
    @Published var isActive = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var progress: Double = 0
    
    private var timerStartDate: Date?
    private var totalDuration: TimeInterval = 0
    private var backgroundEnterTime: Date?
    private var displayTimer: Timer?
    private var isAppInBackground = false
    
    // Screen sleep control
    @Published var preventScreenSleep = false {
        didSet {
            DispatchQueue.main.async {
                UIApplication.shared.isIdleTimerDisabled = self.preventScreenSleep
            }
        }
    }
    
    init() {
        setupBackgroundObservers()
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopTimer()
        // Always restore screen sleep when timer manager is deallocated
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    // MARK: - Timer Control
    
    func startTimer(duration: TimeInterval, timerName: String) {
        stopTimer() // Stop any existing timer
        
        totalDuration = duration
        timeRemaining = duration
        timerStartDate = Date()
        isActive = true
        progress = 0
        
        // Prevent screen sleep during meditation
        preventScreenSleep = true
        
        // Schedule completion notification
        scheduleCompletionNotification(duration: duration, timerName: timerName)
        
        // Start display update timer
        startDisplayTimer()
        
    }
    
    func stopTimer() {
        isActive = false
        timerStartDate = nil
        backgroundEnterTime = nil
        displayTimer?.invalidate()
        displayTimer = nil
        
        // Re-enable screen sleep
        preventScreenSleep = false
        
        // Cancel pending notifications
        cancelNotifications()
        
    }
    
    func pauseTimer() {
        if isActive {
            isActive = false
            displayTimer?.invalidate()
            displayTimer = nil
            
            // Allow screen sleep when paused
            preventScreenSleep = false
            
        }
    }
    
    func resumeTimer() {
        if !isActive && timerStartDate != nil {
            isActive = true
            startDisplayTimer()
            
            // Prevent screen sleep when resumed
            preventScreenSleep = true
            
        }
    }
    
    // MARK: - Display Timer
    
    private func startDisplayTimer() {
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateDisplay()
        }
    }
    
    private func updateDisplay() {
        guard let startDate = timerStartDate else { return }
        
        let elapsed = Date().timeIntervalSince(startDate)
        let remaining = max(0, totalDuration - elapsed)
        
        DispatchQueue.main.async {
            self.timeRemaining = remaining
            self.progress = elapsed / self.totalDuration
            
            if remaining <= 0 {
                self.timerCompleted()
            }
        }
    }
    
    private func timerCompleted() {
        
        stopTimer()
        
        // Show completion notification if app is in background
        if isAppInBackground {
            showLocalCompletionNotification()
        }
    }
    
    // MARK: - Background Handling
    
    private func setupBackgroundObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        isAppInBackground = true
        backgroundEnterTime = Date()
        
        #if DEBUG
        print("📱 App entered background - Timer continues with system time tracking")
        #endif
    }
    
    @objc private func appWillEnterForeground() {
        isAppInBackground = false
        
        guard let startDate = timerStartDate else { return }
        
        // Recalculate based on actual system time elapsed
        let totalElapsed = Date().timeIntervalSince(startDate)
        let remaining = max(0, totalDuration - totalElapsed)
        
        DispatchQueue.main.async {
            self.timeRemaining = remaining
            self.progress = totalElapsed / self.totalDuration
            
            if remaining <= 0 {
                self.timerCompleted()
            } else if self.isActive {
                // Restart display timer if still active
                self.startDisplayTimer()
                // Re-enable screen sleep prevention if timer is still running
                self.preventScreenSleep = true
            }
        }
        
        #if DEBUG
        print("📱 App entered foreground - Timer state updated: \(remaining)s remaining")
        #endif
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            #if DEBUG
            if granted {
                print("✅ Notification permission granted")
            } else if let error = error {
                print("❌ Notification permission error: \(error)")
            }
            #endif
        }
    }
    
    private func scheduleCompletionNotification(duration: TimeInterval, timerName: String) {
        let content = UNMutableNotificationContent()
        content.title = "🧘‍♀️ Meditasyon Tamamlandı"
        content.body = "\(timerName) meditasyonunuz başarıyla tamamlandı!"
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
        let request = UNNotificationRequest(
            identifier: "meditation-timer-completion",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { _ in
            // Notification scheduled silently
        }
    }
    
    private func showLocalCompletionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🧘‍♀️ Meditasyon Tamamlandı"
        content.body = "Meditasyonunuz başarıyla tamamlandı! Harika iş çıkardınız."
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "meditation-timer-local-completion",
            content: content,
            trigger: nil // Immediate notification
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["meditation-timer-completion", "meditation-timer-local-completion"]
        )
    }
    
    // MARK: - Utility
    
    func formatTime(_ time: TimeInterval) -> String {
        return TimeUtilities.formatTime(time)
    }
}