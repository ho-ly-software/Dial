//
//  MenuBarMenuView.swift
//  Dial
//
//  Created by KrLite on 2024/3/24.
//

import SwiftUI
import Defaults
import SFSafeSymbols
import SettingsAccess

struct MenuBarMenuView: View {
    @Environment(\.openWindow) private var openWindow
    
    @State var isConnected: Bool = false
    @State var serial: String? = nil
    
    @Default(.activatedControllerIDs) var activatedControllerIDs
    @Default(.currentControllerID) var currentControllerID
    
    @Default(.globalHapticsEnabled) var globalHapticsEnabled
    @Default(.globalScrollSmoothEnabled) var globalScrollSmoothEnabled
    @Default(.globalSensitivity) var globalSensitivity
    @Default(.globalDirection) var globalDirection
    
    func possibleChar(from int: Int) -> Character? {
        return String(int).first
    }
    
    var body: some View {
        // MARK: - Status
        
        Button {
            // Nothing to do
        } label: {
            Label("Surface Dial", systemSymbol: .hockeyPuck)
        }
        .disabled(true)
        .orSomeView(condition: !isConnected) {
            Button {
                dial.connect()
            } label: {
                Label("Surface Dial", systemSymbol: .arrowTriangle2Circlepath)
            }
        }
        
        Divider()
        
        // MARK: - Controllers
        
        Text("Controllers")
        
        ForEach(Array($activatedControllerIDs.enumerated()), id: \.offset) { index, id in
            Toggle(isOn: id.isCurrent) {
                Label(id.wrappedValue.controller.name ?? controllerNamePlaceholder, systemSymbol: id.wrappedValue.controller.symbol)
            }
            .possibleKeyboardShortcut(
                possibleChar(from: index).map { KeyEquivalent.init($0) },
                modifiers: .option
            )
        }
        
        Divider()
        
        // MARK: - Quick Settings
        
        Text("Quick Settings")
        
        Toggle(isOn: $globalHapticsEnabled) {
            Text(.init(localized: .init("Menu: Haptics", defaultValue: "Haptic Feedback")))
        }
        
        Toggle(isOn: $globalScrollSmoothEnabled) {
            Text(.init(localized: .init("Menu: Smooth Scroll", defaultValue: "Smooth Scroll")))
        }
        
        Picker(selection: $globalSensitivity) {
            ForEach(Sensitivity.allCases) { sensitivity in
                Label(sensitivity.title, systemSymbol: sensitivity.symbol)
            }
        } label: {
            Label {
                Text(.init(localized: .init("Menu: Sensitivity", defaultValue: "Sensitivity")))
            } icon: {
                Image(systemSymbol: globalSensitivity.symbol)
            }
        }
        
        Picker(selection: $globalDirection) {
            ForEach(Direction.allCases) { direction in
                Label(direction.title, systemSymbol: direction.symbol)
            }
        } label: {
            Label {
                Text(.init(localized: .init("Menu: Direction", defaultValue: "Direction")))
            } icon: {
                Image(systemSymbol: globalDirection.symbol)
            }
        }
        
        Divider()
        
        // MARK: - Settings & App Controls
        
        SettingsLink(
            label: { Text("Settings…") },
            preAction: {
                NSApp.activate(ignoringOtherApps: true)
            },
            postAction: { }
        )
        .keyboardShortcut(",", modifiers: .command)
        
        Button("About \(Bundle.main.appName)…") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "about")
        }
        .keyboardShortcut("i", modifiers: .command)
        
        Divider()
        
        Button("Quit") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
        .task {
            // MARK: Update conenction status
            
            for await _ in observationTrackingStream({ dial.hardware.connectionStatus }) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let connectionStatus = dial.hardware.connectionStatus
                    isConnected = connectionStatus.isConnected
                    
                    switch connectionStatus {
                    case .connected(let string):
                        serial = string
                    case .disconnected:
                        serial = nil
                    }
                }
            }
        }
    }
}
