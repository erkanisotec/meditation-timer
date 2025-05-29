import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let strokeWidth: CGFloat
    let size: CGFloat
    
    init(progress: Double, strokeWidth: CGFloat = 8, size: CGFloat = 200) {
        self.progress = progress
        self.strokeWidth = strokeWidth
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: strokeWidth)
                .frame(width: size, height: size)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
    }
}

struct TimerDisplayView: View {
    let timeRemaining: TimeInterval
    let totalTime: TimeInterval
    var progress: Double = 0
    
    var body: some View {
        ZStack {
            CircularProgressView(
                progress: progress > 0 ? progress : 1.0 - (timeRemaining / totalTime),
                size: 280
            )
            
            VStack(spacing: 8) {
                Text(formatTime(timeRemaining))
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .foregroundColor(.primary)
                    .monospacedDigit()
                
                Text("kalan süre")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        return TimeUtilities.formatTime(time)
    }
}

#Preview {
    VStack(spacing: 40) {
        CircularProgressView(progress: 0.7, size: 150)
        TimerDisplayView(timeRemaining: 1830, totalTime: 3600)
    }
    .padding()
}