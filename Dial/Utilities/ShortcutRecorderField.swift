//
//  ShortcutRecorderField.swift
//  Dial
//
//  Created by KrLite on 2024/3/30.
//

import SwiftUI
import AppKit
import SFSafeSymbols

struct ShortcutRecorderField: View {
    @Binding var shortcut: ShortcutArray
    @State private var isRecording: Bool = false
    @State private var eventMonitor: Any?
    
    var placeholder: String = "Click to record shortcut"
    
    var body: some View {
        HStack(spacing: 8) {
            Button {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                HStack(spacing: 4) {
                    if isRecording {
                        Text("Type shortcut…")
                            .font(.callout)
                            .foregroundColor(.accentColor)
                    } else if shortcut.isEmpty {
                        Text(placeholder)
                            .font(.callout)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(modifierSymbols, id: \.self) { symbol in
                            KeyBadge(text: symbol)
                        }
                        ForEach(shortcut.sortedKeys, id: \.self) { key in
                            KeyBadge(text: key.name)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(minWidth: 140, minHeight: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(isRecording ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isRecording ? 2 : 1)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isRecording ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
                        )
                )
            }
            .buttonStyle(.plain)
            
            if !shortcut.isEmpty {
                Button {
                    shortcut = ShortcutArray()
                    if isRecording {
                        stopRecording()
                    }
                } label: {
                    Image(systemSymbol: .xmarkCircleFill)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear shortcut")
            }
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    private var modifierSymbols: [String] {
        var symbols: [String] = []
        if shortcut.modifiers.contains(.control) { symbols.append("⌃") }
        if shortcut.modifiers.contains(.option) { symbols.append("⌥") }
        if shortcut.modifiers.contains(.shift) { symbols.append("⇧") }
        if shortcut.modifiers.contains(.command) { symbols.append("⌘") }
        if shortcut.modifiers.contains(.capsLock) { symbols.append("⇪") }
        if shortcut.modifiers.contains(.function) { symbols.append("fn") }
        return symbols
    }
    
    private func startRecording() {
        isRecording = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            // Escape cancels recording
            if event.keyCode == 53 {
                stopRecording()
                return nil
            }
            
            let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift, .function])
            // Backspace / Delete with no modifiers clears shortcut
            if (event.keyCode == 51 || event.keyCode == 117) && modifiers.isEmpty {
                shortcut = ShortcutArray()
                stopRecording()
                return nil
            }
            
            if let input = Input(rawValue: Int32(event.keyCode)), input != .unknown {
                shortcut = ShortcutArray(modifiers: modifiers, keys: [input])
                stopRecording()
                return nil
            }
            
            return nil
        }
    }
    
    private func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

private struct KeyBadge: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(nsColor: .tertiaryLabelColor).opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 0.5)
                    )
            )
    }
}
