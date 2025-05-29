import SwiftUI

struct NewTimerView: View {
    @ObservedObject var timerManager: TimerManager
    @Environment(\.dismiss) var dismiss
    
    var editingTemplate: TimerTemplate?
    
    @State private var name = ""
    @State private var hours = 0
    @State private var minutes = 0
    @State private var seconds = 0
    @State private var selectedSound: SoundOption = .singingBowlC
    @State private var backgroundMusicFade = true
    @State private var stopBackgroundMusic = false
    @State private var fadeInterval = 30.0
    @State private var alarmFadeInDuration = 15.0
    
    init(timerManager: TimerManager, editingTemplate: TimerTemplate? = nil) {
        self.timerManager = timerManager
        self.editingTemplate = editingTemplate
        
        if let template = editingTemplate {
            _name = State(initialValue: template.name)
            let duration = Int(template.duration)
            _hours = State(initialValue: duration / 3600)
            _minutes = State(initialValue: (duration % 3600) / 60)
            _seconds = State(initialValue: duration % 60)
            _selectedSound = State(initialValue: template.soundOption)
            _backgroundMusicFade = State(initialValue: template.backgroundMusicFade)
            _stopBackgroundMusic = State(initialValue: template.stopBackgroundMusic)
            _fadeInterval = State(initialValue: template.fadeInterval)
            _alarmFadeInDuration = State(initialValue: template.alarmFadeInDuration)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Timer Adı") {
                    TextField("Timer İsmi", text: $name)
                        .textFieldStyle(.plain)
                }
                
                Section("Süre") {
                    HStack(spacing: 15) {
                        TimePickerCompact(title: "sa", value: $hours, range: 0...23)
                        TimePickerCompact(title: "dk", value: $minutes, range: 0...59)
                        TimePickerCompact(title: "sn", value: $seconds, range: 0...59)
                    }
                    .padding(.vertical, 5)
                }
                
                Section("Ses Ayarları") {
                    Picker("Alarm Sesi", selection: $selectedSound) {
                        ForEach(SoundOption.allCases, id: \.self) { sound in
                            Text(sound.rawValue).tag(sound)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    HStack {
                        Text("Alarm Yükselme")
                        Spacer()
                        Text("\(Int(alarmFadeInDuration))sn")
                            .foregroundColor(.gray)
                    }
                    Slider(value: $alarmFadeInDuration, in: 5...300, step: 5)
                }
                
                Section("Arka Plan Müziği") {
                    Toggle("Arka Plan Müziği Kısılsın", isOn: $backgroundMusicFade)
                    
                    if backgroundMusicFade {
                        HStack {
                            Text("Kısılma Süresi")
                            Spacer()
                            Text("\(Int(fadeInterval))sn")
                                .foregroundColor(.gray)
                        }
                        Slider(value: $fadeInterval, in: 5...120, step: 5)
                    }
                    
                    Toggle("Arka Plan Müziğini Kapat", isOn: $stopBackgroundMusic)
                }
            }
            .navigationTitle(editingTemplate != nil ? "Timer Düzenle" : "Yeni Timer")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") { saveTimer() }
                }
            }
        }
    }
    
    private func saveTimer() {
        let duration = TimeInterval(hours * 3600 + minutes * 60 + seconds)
        let template = TimerTemplate(
            id: editingTemplate?.id ?? UUID(),
            name: name,
            duration: duration,
            soundOption: selectedSound,
            backgroundMusicFade: backgroundMusicFade,
            stopBackgroundMusic: stopBackgroundMusic,
            fadeInterval: fadeInterval,
            alarmFadeInDuration: alarmFadeInDuration
        )
        
        if let editingTemplate = editingTemplate,
           let index = timerManager.templates.firstIndex(where: { $0.id == editingTemplate.id }) {
            timerManager.templates[index] = template
        } else {
            timerManager.templates.append(template)
        }
        
        timerManager.saveTemplates()
        dismiss()
    }
}

struct TimePickerCompact: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Picker("", selection: $value) {
                ForEach(range, id: \.self) { number in
                    Text("\(number)").tag(number)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 100)
            .clipped()
        }
    }
} 