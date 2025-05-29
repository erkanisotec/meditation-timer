//
//  ContentView.swift
//  Meditasyon Timer
//
//  Created by Erkan Öztürk on 16.02.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var timerManager = TimerManager()
    @State private var showingNewTemplate = false
    @State private var editingTemplate: TimerTemplate? = nil
    @State private var selectedTimer: TimerTemplate? = nil
    
    var body: some View {
        NavigationSplitView {
            ZStack {
                VStack(spacing: 0) {
                    HeaderView()
                    TimerListView(
                        timerManager: timerManager,
                        onEdit: { template in editingTemplate = template },
                        onDelete: deleteItems,
                        onSelect: { template in selectedTimer = template }
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
                ModernTimerView(template: template, timerManager: timerManager)
            }
        } detail: {
            Text("Timer seçin")
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

#Preview {
    ContentView()
}

