# 🧘‍♀️ Meditasyon Timer

A modern, elegant iOS meditation timer app built with SwiftUI. Features customizable meditation sessions, background execution support, and beautiful circular progress indicators.

## ✨ Features

### 🎯 Core Functionality
- **Custom Timer Templates**: Create and save personalized meditation sessions
- **Background Execution**: Timers continue running even when the phone screen is locked
- **Multiple Sound Options**: Choose from various Tibetan singing bowls and nature sounds
- **Fade-in Audio**: Gradual volume increase for gentle meditation endings
- **Local Notifications**: Get notified when your meditation session is complete

### 🎨 Modern UI
- **Circular Progress Indicators**: Beautiful gradient-based progress visualization
- **Full-screen Timer View**: Immersive meditation experience
- **Pause/Resume Support**: Flexible control over your meditation sessions
- **Completion Animations**: Celebrating successful meditation sessions
- **Accessibility Support**: VoiceOver labels for all interactive elements

### 🔧 Advanced Features
- **Screen Sleep Prevention**: Keeps screen awake during meditation
- **Background Music Management**: Option to fade or stop background music
- **Time Formatting Utilities**: Consistent time display across the app
- **Memory Management**: Proper cleanup of timers and background tasks

## 📱 Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## 🚀 Installation

1. Clone this repository
```bash
git clone https://github.com/yourusername/meditasyon-timer.git
```

2. Open `Meditasyon Timer.xcodeproj` in Xcode

3. Build and run on your iOS device or simulator

## 🎵 Sound Files

The app includes several meditation sounds:
- **Tibetan Singing Bowl (C-tuned)**: Traditional meditation bell
- **Tibetan Singing Bowl (Moon Notes)**: With binaural beats
- **Long Singing Bowl**: Extended resonance
- **Nature Music**: Atmospheric background music

## 🏗️ Architecture

### MVVM Pattern
- **Models**: `TimerTemplate` for session configuration
- **ViewModels**: `TimerManager` and `BackgroundTimerManager` for business logic
- **Views**: SwiftUI views with modern design patterns

### Key Components

#### BackgroundTimerManager
Advanced timer management with background execution support:
- System time tracking for accuracy
- Screen sleep prevention
- Local notifications
- App state monitoring

#### AudioManager
Handles all audio playback:
- AVAudioSession configuration
- Fade-in effects
- Background audio management
- Notification integration

#### Modern UI Components
- `CircularProgressView`: Gradient-based progress indicators
- `TimerDisplayView`: Enhanced time visualization
- `ModernTimerView`: Full-screen timer experience

## 📁 Project Structure

```
Meditasyon Timer/
├── Meditasyon_TimerApp.swift       # App entry point
├── ContentView.swift               # Main application view
├── Models/
│   └── TimerTemplate.swift         # Timer configuration model
├── ViewModels/
│   ├── TimerManager.swift          # Legacy timer management
│   └── BackgroundTimerManager.swift # Advanced background timer
├── Views/
│   ├── NewTimerView.swift          # Timer creation/editing
│   ├── ModernTimerView.swift       # Full-screen timer experience
│   ├── CircularProgressView.swift  # Progress visualization
│   ├── TimerRowView.swift          # Timer list item
│   ├── TimerControlView.swift      # Timer controls
│   └── TimerDisplayView.swift      # Time display component
├── Managers/
│   └── AudioManager.swift          # Audio playback management
└── Utilities/
    └── TimeUtilities.swift         # Time formatting functions
```

## 🔧 Usage

### Creating a Timer
1. Tap the "+" button to create a new timer
2. Set your desired duration (hours, minutes, seconds)
3. Choose your preferred alarm sound
4. Configure background music settings
5. Save your timer template

### Starting a Meditation
1. Select a timer from your saved templates
2. Tap to open the full-screen timer view
3. Press the play button to start your session
4. Your timer will continue running even if you lock your phone
5. Receive a notification when your meditation is complete

### Background Features
- **Screen Sleep Prevention**: Your screen stays awake during meditation
- **System Time Tracking**: Accurate timing even when app is backgrounded
- **Smart Resume**: Seamlessly continue after app switching

## 🎨 Design Philosophy

The app follows iOS Human Interface Guidelines with:
- **Minimal, clean interface** for distraction-free meditation
- **Consistent visual hierarchy** using typography and spacing
- **Accessible design** with proper contrast and VoiceOver support
- **Smooth animations** for delightful user experience

## 🛠️ Technical Highlights

### Background Execution
```swift
// Screen sleep prevention during meditation
UIApplication.shared.isIdleTimerDisabled = true

// System time tracking for accuracy
let elapsedTime = Date().timeIntervalSince(startTime)
let remainingTime = totalDuration - elapsedTime
```

### Modern SwiftUI Patterns
- `@StateObject` and `@ObservedObject` for state management
- Environment values for clean data flow
- Accessibility labels for inclusive design
- Modern navigation patterns with `.toolbar`

### Memory Management
- Proper timer cleanup in `deinit`
- Background task management
- Weak references to prevent retain cycles

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is available under the MIT license. See the LICENSE file for more info.

## 🙏 Acknowledgments

- Tibetan singing bowl samples from Freesound.org
- Nature music from atmospheric sound collections
- SwiftUI community for inspiration and best practices

---

**Enjoy your meditation journey! 🧘‍♀️✨**