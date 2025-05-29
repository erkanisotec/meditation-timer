import SwiftUI

struct TimerControlView: View {
    let template: TimerTemplate
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        Group {
            if timerManager.isAlarmPlaying[template.id] == true {
                AlarmAnimationView(template: template, timerManager: timerManager)
            } else if timerManager.isRunning[template.id] == true {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.blue)
                    StopButton(template: template, timerManager: timerManager)
                }
            } else {
                PlayButton(template: template, timerManager: timerManager)
            }
        }
    }
}

struct AlarmAnimationView: View {
    let template: TimerTemplate
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Ses dalgası animasyonu
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    AlarmBar(
                        volume: timerManager.alarmVolumes[template.id] ?? 0,
                        delay: Double(index) * 0.2
                    )
                }
            }
            .frame(width: 30)
            
            // Ses yüzdeliği ve kalan süre
            VStack(alignment: .leading, spacing: 2) {
                Text("%\(Int((timerManager.alarmVolumes[template.id] ?? 0) * 100))")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                if let remainingTime = timerManager.fadeInRemainingTime[template.id], remainingTime > 0 {
                    Text("\(Int(remainingTime))sn")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 40, alignment: .leading)
            
            // Stop butonu
            StopButton(template: template, timerManager: timerManager)
        }
        .frame(height: 35)
    }
}

struct AlarmBar: View {
    let volume: Float
    let delay: Double
    
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.orange)
            .frame(width: 3, height: getHeight())
            .animation(.linear(duration: 0.1), value: volume)
    }
    
    private func getHeight() -> CGFloat {
        let minHeight: CGFloat = 10
        let maxHeight: CGFloat = 30
        return minHeight + (maxHeight - minHeight) * CGFloat(volume)
    }
}

struct PlayButton: View {
    let template: TimerTemplate
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        Button(action: { timerManager.startTimer(template: template) }) {
            Image(systemName: "play.circle.fill")
                .foregroundColor(.green)
                .font(.title)
        }
        .accessibilityLabel("Timer'ı başlat")
        .accessibilityHint("\(template.name) timer'ını başlatır")
    }
}

struct StopButton: View {
    let template: TimerTemplate
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        Button(action: { timerManager.stopTimer(id: template.id) }) {
            Image(systemName: "stop.circle.fill")
                .foregroundColor(.red)
                .font(.title)
        }
        .accessibilityLabel("Timer'ı durdur")
        .accessibilityHint("\(template.name) timer'ını durdurur ve ses çalmayı keser")
    }
}