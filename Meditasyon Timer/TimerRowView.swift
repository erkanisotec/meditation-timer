import SwiftUI

struct TimerRowWithActions: View {
    let template: TimerTemplate
    @ObservedObject var timerManager: TimerManager
    let onEdit: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        TimerRow(template: template, timerManager: timerManager, onSelect: onSelect)
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    deleteTimer()
                } label: {
                    Label("Sil", systemImage: "trash")
                }
                .accessibilityLabel("Timer'ı sil")
                .accessibilityHint("Bu timer'ı kalıcı olarak siler")
                
                Button(action: onEdit) {
                    Label("Düzenle", systemImage: "pencil")
                }
                .tint(.blue)
                .accessibilityLabel("Timer'ı düzenle")
                .accessibilityHint("Bu timer'ın ayarlarını değiştirin")
            }
    }
    
    private func deleteTimer() {
        if let index = timerManager.templates.firstIndex(where: { $0.id == template.id }) {
            timerManager.templates.remove(at: index)
            timerManager.saveTemplates()
        }
    }
}

struct TimerRow: View {
    let template: TimerTemplate
    @ObservedObject var timerManager: TimerManager
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .accessibilityLabel("Timer adı: \(template.name)")
                        .foregroundColor(.primary)
                    TimerDurationView(template: template, timerManager: timerManager)
                }
                
                Spacer()
                
                TimerControlView(template: template, timerManager: timerManager)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimerDurationView: View {
    let template: TimerTemplate
    @ObservedObject var timerManager: TimerManager
    
    var body: some View {
        HStack(spacing: 2) {
            if let timeLeft = timerManager.activeTimers[template.id] {
                formatDuration(timeLeft)
            } else {
                formatDuration(template.duration)
            }
        }
        .foregroundColor(timerManager.isRunning[template.id] == true ? .blue : .gray)
    }
    
    @ViewBuilder
    private func formatDuration(_ duration: TimeInterval) -> some View {
        let components = formatTimeComponents(duration)
        if components.hours > 0 {
            TimeComponent(value: components.hours, unit: "sa")
        }
        if components.minutes > 0 {
            TimeComponent(value: components.minutes, unit: "dk")
        }
        TimeComponent(value: components.seconds, unit: "sn")
    }
    
    private func formatTimeComponents(_ duration: TimeInterval) -> (hours: Int, minutes: Int, seconds: Int) {
        return TimeUtilities.formatTimeComponents(duration)
    }
}

struct TimeComponent: View {
    let value: Int
    let unit: String
    
    var body: some View {
        Text("\(value)\(unit)")
            .font(.subheadline)
            .padding(.horizontal, 2)
            .accessibilityLabel("\(value) \(unit == "sa" ? "saat" : unit == "dk" ? "dakika" : "saniye")")
    }
}