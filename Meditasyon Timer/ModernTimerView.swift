import SwiftUI

struct ModernTimerView: View {
    let template: TimerTemplate
    @ObservedObject var timerManager: TimerManager
    @StateObject private var backgroundTimer = BackgroundTimerManager()
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 8) {
                        Text(template.name)
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Meditasyon Zamanı")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(1)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Timer Display
                    TimerDisplayView(
                        timeRemaining: backgroundTimer.isActive ? backgroundTimer.timeRemaining : template.duration,
                        totalTime: template.duration,
                        progress: backgroundTimer.progress
                    )
                    
                    Spacer()
                    
                    // Control Buttons
                    VStack(spacing: 20) {
                        if backgroundTimer.timeRemaining <= 0 && backgroundTimer.isActive {
                            CompletedTimerView(template: template, backgroundTimer: backgroundTimer)
                        } else {
                            ModernTimerControlButtons(template: template, backgroundTimer: backgroundTimer)
                        }
                        
                        // Close Button
                        Button("Kapat") {
                            backgroundTimer.stopTimer()
                            dismiss()
                        }
                        .font(.body)
                        .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct TimerControlButtons: View {
    let template: TimerTemplate
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        HStack(spacing: 30) {
            if timerManager.isRunning[template.id] == true {
                // Stop Button
                Button(action: { timerManager.stopTimer(id: template.id) }) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.red)
                        .clipShape(Circle())
                        .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .accessibilityLabel("Timer'ı durdur")
            } else {
                // Start Button
                Button(action: { timerManager.startTimer(template: template) }) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                }
                .accessibilityLabel("Timer'ı başlat")
            }
        }
    }
}

struct AlarmPlayingView: View {
    let template: TimerTemplate
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Meditation Complete Text
            VStack(spacing: 8) {
                Text("🧘‍♀️")
                    .font(.system(size: 40))
                
                Text("Meditasyon Tamamlandı")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text("Harika iş çıkardınız!")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Sound Wave Animation
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    SoundWaveBar(
                        volume: timerManager.alarmVolumes[template.id] ?? 0,
                        delay: Double(index) * 0.1
                    )
                }
            }
            .frame(height: 30)
            
            // Volume and Stop Button
            HStack(spacing: 20) {
                VStack {
                    Text("Ses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("%\(Int((timerManager.alarmVolumes[template.id] ?? 0) * 100))")
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Button(action: { timerManager.stopTimer(id: template.id) }) {
                    Text("Durdur")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(width: 100, height: 44)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal)
    }
}

struct SoundWaveBar: View {
    let volume: Float
    let delay: Double
    
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 4, height: getHeight())
            .animation(.easeInOut(duration: 0.5).delay(delay), value: volume)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever()) {
                    isAnimating.toggle()
                }
            }
    }
    
    private func getHeight() -> CGFloat {
        let minHeight: CGFloat = 8
        let maxHeight: CGFloat = 30
        let height = minHeight + (maxHeight - minHeight) * CGFloat(volume)
        return isAnimating ? height * 1.2 : height
    }
}

struct ModernTimerControlButtons: View {
    let template: TimerTemplate
    @ObservedObject var backgroundTimer: BackgroundTimerManager
    
    var body: some View {
        HStack(spacing: 30) {
            if backgroundTimer.isActive {
                // Pause Button
                Button(action: { backgroundTimer.pauseTimer() }) {
                    Image(systemName: "pause.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.orange)
                        .clipShape(Circle())
                        .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .accessibilityLabel("Timer'ı duraklat")
                
                // Stop Button
                Button(action: { backgroundTimer.stopTimer() }) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.red)
                        .clipShape(Circle())
                        .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .accessibilityLabel("Timer'ı durdur")
            } else {
                // Start/Resume Button
                Button(action: { 
                    if backgroundTimer.timeRemaining > 0 && backgroundTimer.timeRemaining < template.duration {
                        backgroundTimer.resumeTimer()
                    } else {
                        backgroundTimer.startTimer(duration: template.duration, timerName: template.name)
                    }
                }) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                }
                .accessibilityLabel(backgroundTimer.timeRemaining > 0 && backgroundTimer.timeRemaining < template.duration ? "Timer'ı devam ettir" : "Timer'ı başlat")
            }
        }
        
        // Screen Sleep Status
        if backgroundTimer.preventScreenSleep {
            Text("Ekran uyku modunda değil")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.top, 10)
        }
    }
}

struct CompletedTimerView: View {
    let template: TimerTemplate
    @ObservedObject var backgroundTimer: BackgroundTimerManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Completion Animation
            VStack(spacing: 8) {
                Text("🧘‍♀️")
                    .font(.system(size: 60))
                    .scaleEffect(1.2)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: backgroundTimer.timeRemaining)
                
                Text("Meditasyon Tamamlandı!")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Harika iş çıkardınız! 🎉")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Restart Button
            Button(action: { 
                backgroundTimer.startTimer(duration: template.duration, timerName: template.name)
            }) {
                Text("Tekrar Başlat")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 150, height: 44)
                    .background(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    ModernTimerView(
        template: TimerTemplate(name: "Sabah Meditasyonu", duration: 600),
        timerManager: TimerManager()
    )
}