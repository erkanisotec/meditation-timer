import Foundation

struct TimerTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var duration: TimeInterval
    var soundOption: SoundOption
    var backgroundMusicFade: Bool
    var stopBackgroundMusic: Bool
    var fadeInterval: TimeInterval
    var alarmFadeInDuration: TimeInterval
    
    init(id: UUID = UUID(), 
         name: String = "", 
         duration: TimeInterval = 0,
         soundOption: SoundOption = .singingBowlC,
         backgroundMusicFade: Bool = true,
         stopBackgroundMusic: Bool = false,
         fadeInterval: TimeInterval = 30,
         alarmFadeInDuration: TimeInterval = 15) {
        self.id = id
        self.name = name
        self.duration = duration
        self.soundOption = soundOption
        self.backgroundMusicFade = backgroundMusicFade
        self.stopBackgroundMusic = stopBackgroundMusic
        self.fadeInterval = fadeInterval
        self.alarmFadeInDuration = alarmFadeInDuration
    }
}

enum SoundOption: String, Codable, CaseIterable {
    case singingBowlC = "Tibet Çanı (C)"
    case singingBowlMoon = "Tibet Çanı (Ay Notası)"
    case singingBowlLong = "Tibet Çanı (Uzun)"
    case natureMusic = "Doğa Müziği"
    
    var fileName: String {
        switch self {
        case .singingBowlC: return "204917__brodjaman__singing-bowl-c-tuned"
        case .singingBowlMoon: return "239910__the_very_real_horst__79-tibetan-singing-bowl-moon-nodes-and-makemake-with-binaural-beats"
        case .singingBowlLong: return "573805__hollandm__singing-bowl-long-without-reverb"
        case .natureMusic: return "711018__muyo5438__atmosphere-music-for-nature-movies"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .natureMusic: return "mp3"
        default: return "wav"
        }
    }
} 