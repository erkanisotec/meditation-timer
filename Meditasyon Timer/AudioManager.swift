import AVFoundation
import UserNotifications

class AudioManager {
    static let shared = AudioManager()
    private var audioPlayer: AVAudioPlayer?
    private var fadeInTimer: Timer?
    
    private init() {
        setupAudioSession()
        requestNotificationPermission()
    }
    
    private func setupAudioSession() {
        do {
            // Arka planda çalışma için session ayarları
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Arka plan ses kontrolünü etkinleştir
            try AVAudioSession.sharedInstance().setCategory(.playback)
            
        } catch {
            // Audio session setup failed
        }
    }
    
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
            // Notification permission request completed
        }
    }
    
    private func stopBackgroundAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .soloAmbient,
                mode: .default,
                options: [.duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Background audio stop failed
        }
    }
    
    private func allowBackgroundAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Background audio permission failed
        }
    }
    
    func playSound(_ sound: SoundOption, fadeInDuration: TimeInterval, stopBackground: Bool = false) {
        stopSound()
        
        if stopBackground {
            stopBackgroundAudio()
        } else {
            allowBackgroundAudio()
        }
        
        guard let soundURL = Bundle.main.url(forResource: sound.fileName, withExtension: sound.fileExtension) else {
            return
        }
        
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            guard let player = audioPlayer else {
                return
            }
            
            player.volume = 0.0
            player.numberOfLoops = -1 // Sürekli tekrar
            player.prepareToPlay()
            
            if player.play() {
                startFadeIn(duration: fadeInDuration)
            }
            
        } catch {
            // Audio playback failed
        }
    }
    
    private func startFadeIn(duration: TimeInterval) {
        let startTime = Date()
        
        fadeInTimer?.invalidate()
        fadeInTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.audioPlayer else {
                timer.invalidate()
                return
            }
            
            let elapsedTime = Date().timeIntervalSince(startTime)
            if elapsedTime >= duration {
                player.volume = 1.0
                timer.invalidate()
                self.fadeInTimer = nil
                return
            }
            
            let progress = min(elapsedTime / duration, 1.0)
            player.volume = Float(progress)
        }
    }
    
    func stopSound() {
        fadeInTimer?.invalidate()
        fadeInTimer = nil
        
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        audioPlayer = nil
        
        // Arka plan müziğine izin ver
        allowBackgroundAudio()
    }
    
    func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
} 