//
//  ContentView.swift
//  Meditasyon Timer
//
//  Created by Erkan Öztürk on 16.02.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var timerManager = TimerManager()
    @StateObject private var globalBackgroundTimer = BackgroundTimerManager()
    @State private var showingNewTemplate = false
    @State private var editingTemplate: TimerTemplate? = nil
    @State private var selectedTimer: TimerTemplate? = nil
    @State private var activeTimerTemplate: TimerTemplate? = nil
    
    var body: some View {
        NavigationSplitView {
            ZStack {
                VStack(spacing: 0) {
                    HeaderView()
                    
                    // Running timer indicator
                    if globalBackgroundTimer.isActive, let activeTemplate = activeTimerTemplate {
                        RunningTimerBanner(
                            template: activeTemplate,
                            backgroundTimer: globalBackgroundTimer,
                            onTap: { selectedTimer = activeTemplate }
                        )
                    }
                    
                    TimerListView(
                        timerManager: timerManager,
                        onEdit: { template in editingTemplate = template },
                        onDelete: deleteItems,
                        onSelect: { template in 
                            selectedTimer = template
                            activeTimerTemplate = template
                        }
                    )
                }
                
                FloatingActionButton {
                    showingNewTemplate = true
                }
            }
            .sheet(isPresented: $showingNewTemplate) {
                NewTimerView(timerManager: timerManager)
            }
            .sheet(item: $editingTemplate) { template in
                NewTimerView(timerManager: timerManager, editingTemplate: template)
            }
            .sheet(item: $selectedTimer) { template in
                ModernTimerView(template: template, backgroundTimer: globalBackgroundTimer)
                    .onAppear {
                        activeTimerTemplate = template
                    }
            }
        } detail: {
            Text("Timer seçin")
        }
        .onChange(of: globalBackgroundTimer.timeRemaining) { _, newValue in
            // Clear active timer when completed
            if newValue <= 0 && !globalBackgroundTimer.isActive {
                activeTimerTemplate = nil
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        timerManager.templates.remove(atOffsets: offsets)
        timerManager.saveTemplates()
    }
}

struct HeaderView: View {
    var body: some View {
        Text("Meditasyon Timer")
            .font(.system(size: 28, weight: .bold))
            .padding(.vertical)
    }
}

struct TimerListView: View {
    @ObservedObject var timerManager: TimerManager
    let onEdit: (TimerTemplate) -> Void
    let onDelete: (IndexSet) -> Void
    let onSelect: (TimerTemplate) -> Void
    
    var body: some View {
        List {
            ForEach(timerManager.templates) { template in
                Section {
                    TimerRowWithActions(
                        template: template,
                        timerManager: timerManager,
                        onEdit: { onEdit(template) },
                        onSelect: { onSelect(template) }
                    )
                }
            }
            .onDelete(perform: onDelete)
        }
    }
}

struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: action) {
                    ZStack {
                        Circle()
                            .fill(.blue)
                            .frame(width: 60, height: 60)
                            .shadow(radius: 5)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
                .accessibilityLabel("Yeni timer ekle")
                .accessibilityHint("Yeni bir meditasyon timer'ı oluşturun")
                .padding(.trailing, 20)
                .padding(.bottom, 30)
            }
        }
    }
}

struct RunningTimerBanner: View {
    let template: TimerTemplate
    @ObservedObject var backgroundTimer: BackgroundTimerManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Timer icon with animation
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "timer")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.blue)
                        .scaleEffect(backgroundTimer.isActive ? 1.0 : 0.8)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: backgroundTimer.isActive)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(backgroundTimer.isActive ? "Çalışıyor" : "Duraklatıldı")
                            .font(.caption)
                            .foregroundColor(backgroundTimer.isActive ? .green : .orange)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatTime(backgroundTimer.timeRemaining))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Progress circle
                ZStack {
                    Circle()
                        .stroke(.gray.opacity(0.3), lineWidth: 3)
                        .frame(width: 30, height: 30)
                    
                    Circle()
                        .trim(from: 0, to: backgroundTimer.progress)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(backgroundTimer.progress * 100))%")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
}

