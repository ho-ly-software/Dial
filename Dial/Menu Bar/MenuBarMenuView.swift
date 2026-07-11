//
//  MenuBarMenuView.swift
//  Dial
//
//  Created by KrLite on 2024/3/24.
//

import SwiftUI
import SettingsAccess
import Defaults
import LaunchAtLogin

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
    
    @Default(.dialMenuThickness) var dialMenuThickness
    @Default(.dialMenuAnimation) var dialMenuAnimation
    @Default(.dialMenuAppearsAtCursor) var dialMenuAppearsAtCursor
    
    @ObservedObject var startsWithMacOS = LaunchAtLogin.observable
    
    func possibleChar(from int: Int) -> Character? {
        return String(int).first
    }
    
    var body: some View {
        // MARK: - Status
        
        Button {
            // Nothing to do
        } label: {
            Text("Surface Dial")
            Image(systemSymbol: .hockeyPuck)
        }
        .disabled(true)
        .badge(Text(serial ?? ""))
        .orSomeView(condition: !isConnected) {
            Button {
                dial.connect()
            } label: {
                Image(systemSymbol: .arrowTriangle2Circlepath)
                Text("Surface Dial")
            }
            .badge(Text("disconnected"))
        }
        
        Divider()
        
        // MARK: - Controllers
        
        Text("Controllers")
            .badge(Text("press and hold dial"))
        
        ForEach(Array($activatedControllerIDs.enumerated()), id: \.offset) { index, id in
            Toggle(isOn: id.isCurrent) {
                id.wrappedValue.controller.symbol.image
                Text(id.wrappedValue.controller.name ?? controllerNamePlaceholder)
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
                Text(sensitivity.title)
                    .badge(Text(Image(systemSymbol: sensitivity.symbol)))
            }
        } label: {
            Text(.init(localized: .init("Menu: Sensitivity", defaultValue: "Sensitivity")))
        }
        .badge(Text(Image(systemSymbol: globalSensitivity.symbol)))
        
        Picker(selection: $globalDirection) {
            ForEach(Direction.allCases) { direction in
                Text(direction.title)
                    .badge(Text(Image(systemSymbol: direction.symbol)))
            }
        } label: {
            Text(.init(localized: .init("Menu: Direction", defaultValue: "Direction")))
        }
        .badge(Text(Image(systemSymbol: globalDirection.symbol)))
        
        Divider()
        
        // MARK: - On-Screen Dial Menu
        
        Text("On-Screen Dial Menu")
        
        Toggle(isOn: $dialMenuAppearsAtCursor) {
            Text(.init(localized: .init("Menu: Show Menu at Cursor Position", defaultValue: "Show Menu at Cursor Position")))
        }
        
        Picker(selection: $dialMenuThickness) {
            ForEach(DialMenuThickness.allCases) { thickness in
                Text(thickness.title)
                    .badge(Text(Image(systemSymbol: thickness.symbol)))
            }
        } label: {
            Text(.init(localized: .init("Menu: Menu Thickness", defaultValue: "Menu Thickness")))
        }
        .badge(Text(Image(systemSymbol: dialMenuThickness.symbol)))
        
        Picker(selection: $dialMenuAnimation) {
            ForEach(DialMenuAnimation.allCases) { animation in
                Text(animation.title)
                    .badge(Text(Image(systemSymbol: animation.symbol)))
            }
        } label: {
            Text(.init(localized: .init("Menu: Menu Animation", defaultValue: "Menu Animation")))
        }
        .badge(Text(Image(systemSymbol: dialMenuAnimation.symbol)))
        
        Divider()
        
        // MARK: - More Settings
        
        Toggle(isOn: $startsWithMacOS.isEnabled) {
            Text(.init(localized: .init("Menu: Starts with macOS", defaultValue: "Starts with macOS")))
        }
        
        Button("About \(Bundle.main.appName)…") {
            NSApp.setActivationPolicy(.regular)
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
