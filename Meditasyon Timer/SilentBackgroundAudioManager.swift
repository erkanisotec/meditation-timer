import AVFoundation
import MediaPlayer

class SilentBackgroundAudioManager {
    static let shared = SilentBackgroundAudioManager()
    private var audioPlayer: AVAudioPlayer?
    private var timerName: String = ""
    private var remainingTime: TimeInterval = 0
    private var totalDuration: TimeInterval = 0
    private var updateTimer: Timer?
    private var isPaused: Bool = false
    
    private init() {
        setupAudioSession()
        setupRemoteCommandCenter()
    }
    
    deinit {
        stopBackgroundAudio()
    }
    
    private func setupAudioSession() {
        do {
            // Background audio session for lock screen visibility
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Disable all commands to prevent user interaction
        commandCenter.playCommand.isEnabled = false
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.stopCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
    }
    
    func startBackgroundAudio(timerName: String, duration: TimeInterval) {
        self.timerName = timerName
        self.totalDuration = duration
        self.remainingTime = duration
        
        // Create silent audio file programmatically
        createAndPlaySilentAudio()
        
        // Update media info for lock screen
        updateNowPlayingInfo()
        
        // Start timer to update remaining time
        startUpdateTimer()
    }
    
    private func createAndPlaySilentAudio() {
        // Generate silent audio buffer
        let sampleRate: Double = 44100
        let duration: Double = 1.0 // 1 second of silence, will loop
        let frameCount = Int(sampleRate * duration)
        
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(frameCount))!
        audioBuffer.frameLength = AVAudioFrameCount(frameCount)
        
        // Fill with silence (zeros)
        let data = audioBuffer.floatChannelData![0]
        for i in 0..<frameCount {
            data[i] = 0.0
        }
        
        // Create audio file in memory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioURL = documentsPath.appendingPathComponent("silence.wav")
        
        do {
            let audioFile = try AVAudioFile(forWriting: audioURL, settings: audioFormat.settings)
            try audioFile.write(from: audioBuffer)
            
            // Play the silent audio on loop
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.numberOfLoops = -1 // Infinite loop
            audioPlayer?.volume = 0.0 // Silent
            audioPlayer?.play()
            
        } catch {
            print("Silent audio creation failed: \(error)")
        }
    }
    
    private func startUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateRemainingTime()
        }
    }
    
    private func updateRemainingTime() {
        guard !isPaused else { return }
        
        remainingTime = max(0, remainingTime - 1)
        updateNowPlayingInfo()
        
        if remainingTime <= 0 {
            stopBackgroundAudio()
        }
    }
    
    func pauseBackgroundAudio() {
        isPaused = true
        audioPlayer?.pause()
        updateNowPlayingInfo()
    }
    
    func resumeBackgroundAudio() {
        isPaused = false
        audioPlayer?.play()
        updateNowPlayingInfo()
    }
    
    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = timerName
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Meditasyon Timer"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = isPaused ? "Duraklatıldı - \(formatTime(remainingTime))" : "Kalan: \(formatTime(remainingTime))"
        
        // Progress info
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = totalDuration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = totalDuration - remainingTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPaused ? 0.0 : 1.0
        
        // Set artwork (optional - timer icon)
        if let image = createTimerArtwork() {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func createTimerArtwork() -> UIImage? {
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Timer icon
            let timerIconSize: CGFloat = 256
            let timerRect = CGRect(
                x: (size.width - timerIconSize) / 2,
                y: (size.height - timerIconSize) / 2,
                width: timerIconSize,
                height: timerIconSize
            )
            
            UIColor.white.setFill()
            let timerPath = UIBezierPath(ovalIn: timerRect)
            timerPath.fill()
            
            // Add progress indicator
            let progress = (totalDuration - remainingTime) / totalDuration
            let progressRect = timerRect.insetBy(dx: 20, dy: 20)
            
            UIColor.systemBlue.setStroke()
            let progressPath = UIBezierPath(arcCenter: CGPoint(x: progressRect.midX, y: progressRect.midY),
                                         radius: progressRect.width / 2,
                                         startAngle: -CGFloat.pi / 2,
                                         endAngle: -CGFloat.pi / 2 + CGFloat(progress * 2 * Double.pi),
                                         clockwise: true)
            progressPath.lineWidth = 20
            progressPath.stroke()
        }
    }
    
    func stopBackgroundAudio() {
        updateTimer?.invalidate()
        updateTimer = nil
        
        audioPlayer?.stop()
        audioPlayer = nil
        
        isPaused = false
        
        // Clear now playing info
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // Reset audio session safely
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}