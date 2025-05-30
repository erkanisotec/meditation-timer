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
        // Safe cleanup
        displayTimer?.invalidate()
        displayTimer = nil
        
        // Stop background audio safely
        SilentBackgroundAudioManager.shared.stopBackgroundAudio()
        
        // Remove observers
        NotificationCenter.default.removeObserver(self)
        
        // Always restore screen sleep when timer manager is deallocated
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
        }
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
        
        // Start silent background audio for lock screen visibility (like YouTube)
        SilentBackgroundAudioManager.shared.startBackgroundAudio(timerName: timerName, duration: duration)
        
        // Start display update timer
        startDisplayTimer()
        
    }
    
    func stopTimer() {
        isActive = false
        displayTimer?.invalidate()
        displayTimer = nil
        
        // Reset timer state for fresh start
        timerStartDate = nil
        backgroundEnterTime = nil
        timeRemaining = 0
        progress = 0
        
        // Re-enable screen sleep
        preventScreenSleep = false
        
        // Stop silent background audio
        SilentBackgroundAudioManager.shared.stopBackgroundAudio()
        
        // Clear app badge
        BadgeManager.clearBadge()
    }
    
    func pauseTimer() {
        guard isActive else { return }
        
        isActive = false
        displayTimer?.invalidate()
        displayTimer = nil
        
        // Allow screen sleep when paused
        preventScreenSleep = false
        
        // Pause silent background audio
        SilentBackgroundAudioManager.shared.pauseBackgroundAudio()
        print("Timer paused")
    }
    
    func resumeTimer() {
        guard !isActive && timerStartDate != nil && timeRemaining > 0 else { return }
        
        isActive = true
        startDisplayTimer()
        
        // Prevent screen sleep when resumed
        preventScreenSleep = true
        
        // Resume silent background audio
        SilentBackgroundAudioManager.shared.resumeBackgroundAudio()
        print("Timer resumed")
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
        let progressValue = elapsed / totalDuration
        
        DispatchQueue.main.async {
            self.timeRemaining = remaining
            self.progress = progressValue
            
            // No manual updates needed - silent audio manager handles this automatically
            
            if remaining <= 0 {
                self.timerCompleted()
            }
        }
    }
    
    private func timerCompleted() {
        // Mark as completed first
        DispatchQueue.main.async {
            self.isActive = false
            self.timeRemaining = 0
            self.progress = 1.0
        }
        
        // Safe stop with delay to allow UI updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.stopTimer()
        }
        
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
                
                // Silent audio manager automatically updates lock screen info
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
        // No notifications will be sent - silent operation only
    }
    
    private func showLocalCompletionNotification() {
        // No notifications will be sent - silent operation only
    }
    
    private func cancelNotifications() {
        // No notifications to cancel - silent operation only
        BadgeManager.clearBadge()
    }
    
    // MARK: - Utility
    
    func formatTime(_ time: TimeInterval) -> String {
        return TimeUtilities.formatTime(time)
    }
}