import Foundation
import SwiftUI
import UserNotifications

class TimerManager: ObservableObject {
    @Published var templates: [TimerTemplate] = []
    @Published var activeTimers: [UUID: TimeInterval] = [:]
    @Published var isRunning: [UUID: Bool] = [:]
    @Published var alarmVolumes: [UUID: Float] = [:] // Alarm ses seviyesi
    @Published var isAlarmPlaying: [UUID: Bool] = [:] // Alarm çalma durumu
    @Published var fadeInRemainingTime: [UUID: TimeInterval] = [:] // Yükselme kalan süre
    
    private var timers: [UUID: Timer] = [:]
    private var volumeTimers: [UUID: Timer] = [:]
    private var backgroundTasks: [UUID: UIBackgroundTaskIdentifier] = [:]
    private let audioManager = AudioManager.shared
    
    // Background execution support
    private var timerStartTimes: [UUID: Date] = [:]
    private var pausedDurations: [UUID: TimeInterval] = [:]
    private var lastBackgroundTime: [UUID: Date] = [:]
    
    deinit {
        // Cleanup all timers and background tasks
        timers.values.forEach { $0.invalidate() }
        volumeTimers.values.forEach { $0.invalidate() }
        backgroundTasks.values.forEach { taskID in
            if taskID != .invalid {
                UIApplication.shared.endBackgroundTask(taskID)
            }
        }
        
        // Clear app badge
        BadgeManager.clearBadge()
        
        // Remove all pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
    }
    
    init() {
        loadTemplates()
        setupNotifications()
        setupBackgroundObservers()
    }
    
    func startTimer(template: TimerTemplate) {
        // Önceki timer'ı durdur
        stopTimer(id: template.id)
        
        // Arka plan görevi başlat
        let taskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.stopTimer(id: template.id)
        }
        
        guard taskID != .invalid else {
            return
        }
        
        backgroundTasks[template.id] = taskID
        
        // Background execution setup
        let startTime = Date()
        timerStartTimes[template.id] = startTime
        
        activeTimers[template.id] = template.duration
        isRunning[template.id] = true
        alarmVolumes[template.id] = 0
        isAlarmPlaying[template.id] = false
        
        // Schedule completion notification
        scheduleTimerNotification(for: template, startTime: startTime)
        
        timers[template.id] = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer(id: template.id)
        }
        
        // Timer'ı arka planda çalışması için RunLoop'a ekle
        RunLoop.current.add(timers[template.id]!, forMode: .common)
    }
    
    func stopTimer(id: UUID) {
        timers[id]?.invalidate()
        timers[id] = nil
        volumeTimers[id]?.invalidate()
        volumeTimers[id] = nil
        
        // Arka plan görevini sonlandır
        if let taskID = backgroundTasks[id], taskID != .invalid {
            UIApplication.shared.endBackgroundTask(taskID)
            backgroundTasks.removeValue(forKey: id)
        }
        
        isRunning[id] = false
        activeTimers[id] = nil
        alarmVolumes[id] = 0
        isAlarmPlaying[id] = false
        fadeInRemainingTime[id] = 0
        
        audioManager.stopSound()
        
        // Background tracking cleanup
        timerStartTimes.removeValue(forKey: id)
        pausedDurations.removeValue(forKey: id)
        lastBackgroundTime.removeValue(forKey: id)
        
        // Cancel scheduled notifications
        cancelTimerNotification(for: id)
        
        // Clear badge if no active timers
        if activeTimers.isEmpty {
            BadgeManager.clearBadge()
        }
    }
    
    private func updateTimer(id: UUID) {
        guard let timeLeft = activeTimers[id], timeLeft > 0 else {
            timerCompleted(id: id)
            return
        }
        
        DispatchQueue.main.async {
            self.activeTimers[id] = timeLeft - 1
        }
    }
    
    private func timerCompleted(id: UUID) {
        guard let template = templates.first(where: { $0.id == id }) else { return }
        
        timers[id]?.invalidate()
        timers[id] = nil
        isRunning[id] = false
        activeTimers[id] = nil
        
        // Yeni arka plan görevi başlat (alarm için)
        let taskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.stopTimer(id: id)
        }
        
        guard taskID != .invalid else {
            return
        }
        
        backgroundTasks[id] = taskID
        
        DispatchQueue.main.async {
            self.isAlarmPlaying[id] = true
            self.alarmVolumes[id] = 0
            self.fadeInRemainingTime[id] = template.alarmFadeInDuration
            
            // Ses çal
            self.audioManager.playSound(
                template.soundOption,
                fadeInDuration: template.alarmFadeInDuration,
                stopBackground: template.stopBackgroundMusic
            )
            
            // Bildirim göster
            self.audioManager.showNotification(
                title: "Timer Tamamlandı",
                body: "\(template.name) timer'ı tamamlandı!"
            )
            
            // Kalan süre güncelleme timer'ı
            self.startVolumeAnimation(id: id, duration: template.alarmFadeInDuration)
        }
    }
    
    private func startVolumeAnimation(id: UUID, duration: TimeInterval) {
        let startTime = Date()
        
        volumeTimers[id]?.invalidate()
        volumeTimers[id] = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let elapsedTime = Date().timeIntervalSince(startTime)
            if elapsedTime >= duration {
                DispatchQueue.main.async {
                    self.alarmVolumes[id] = 1.0
                    self.fadeInRemainingTime[id] = 0
                }
                timer.invalidate()
                self.volumeTimers.removeValue(forKey: id)
                return
            }
            
            let progress = elapsedTime / duration
            DispatchQueue.main.async {
                self.alarmVolumes[id] = Float(progress)
                self.fadeInRemainingTime[id] = duration - elapsedTime
            }
        }
    }
    
    func saveTemplate(_ template: TimerTemplate) {
        templates.append(template)
        saveTemplates()
    }
    
    func saveTemplates() {
        if let encoded = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(encoded, forKey: "TimerTemplates")
        }
    }
    
    private func loadTemplates() {
        if let data = UserDefaults.standard.data(forKey: "TimerTemplates"),
           let decoded = try? JSONDecoder().decode([TimerTemplate].self, from: data) {
            templates = decoded
        }
    }
    
    // MARK: - Background Execution Support
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            // Notification permission request completed
        }
    }
    
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
        // Save current time when app goes to background
        let currentTime = Date()
        for id in activeTimers.keys {
            lastBackgroundTime[id] = currentTime
        }
        
    }
    
    @objc private func appWillEnterForeground() {
        // Recalculate timer states when app comes back
        let currentTime = Date()
        
        for (id, startTime) in timerStartTimes {
            guard let template = templates.first(where: { $0.id == id }),
                  isRunning[id] == true else { continue }
            
            // Calculate total elapsed time since timer started
            let totalElapsed = currentTime.timeIntervalSince(startTime)
            let remainingTime = template.duration - totalElapsed
            
            if remainingTime <= 0 {
                // Timer should have completed while in background
                DispatchQueue.main.async {
                    self.timerCompleted(id: id)
                }
            } else {
                // Update remaining time
                DispatchQueue.main.async {
                    self.activeTimers[id] = remainingTime
                }
            }
        }
        
    }
    
    private func scheduleTimerNotification(for template: TimerTemplate, startTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = "🧘‍♀️ Meditasyon Tamamlandı"
        content.body = "\(template.name) süren meditasyonunuz tamamlandı!"
        content.sound = .default
        content.badge = 1
        
        // Calculate completion time
        let completionTime = startTime.addingTimeInterval(template.duration)
        let timeInterval = completionTime.timeIntervalSinceNow
        
        // Only schedule if timer hasn't already completed
        if timeInterval > 0 {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
            let request = UNNotificationRequest(
                identifier: "timer-\(template.id.uuidString)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { _ in
                // Notification scheduled
            }
        }
    }
    
    private func cancelTimerNotification(for id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["timer-\(id.uuidString)"]
        )
        
        // Clear badge when canceling notification
        BadgeManager.clearBadge()
    }
} 