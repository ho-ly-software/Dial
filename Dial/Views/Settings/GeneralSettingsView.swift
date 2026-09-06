//
//  GeneralSettingsView.swift
//  Dial
//
//  Created by KrLite on 2024/3/30.
//

import SwiftUI
import Defaults
import LaunchAtLogin
import SFSafeSymbols

struct GeneralSettingsView: View {
    @Default(.globalHapticsEnabled) var globalHapticsEnabled
    @Default(.globalScrollSmoothEnabled) var globalScrollSmoothEnabled
    @Default(.globalSensitivity) var globalSensitivity
    @Default(.globalDirection) var globalDirection
    
    @Default(.dialMenuThickness) var dialMenuThickness
    @Default(.dialMenuAnimation) var dialMenuAnimation
    @Default(.dialMenuAppearsAtCursor) var dialMenuAppearsAtCursor
    
    @ObservedObject var startsWithMacOS = LaunchAtLogin.observable
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $startsWithMacOS.isEnabled)
                Toggle("Haptic Feedback", isOn: $globalHapticsEnabled)
                Toggle("Smooth Scroll", isOn: $globalScrollSmoothEnabled)
            } header: {
                Text("General")
            }
            
            Section {
                Picker("Sensitivity", selection: $globalSensitivity) {
                    ForEach(Sensitivity.allCases) { sensitivity in
                        Text(sensitivity.title).tag(sensitivity)
                    }
                }
                
                Picker("Direction", selection: $globalDirection) {
                    ForEach(Direction.allCases) { direction in
                        Text(direction.title).tag(direction)
                    }
                }
            } header: {
                Text("Dial Hardware")
            }
            
            Section {
                Toggle("Show Menu at Cursor Position", isOn: $dialMenuAppearsAtCursor)
                
                Picker("Menu Thickness", selection: $dialMenuThickness) {
                    ForEach(DialMenuThickness.allCases) { thickness in
                        Text(thickness.title).tag(thickness)
                    }
                }
                
                Picker("Menu Animation", selection: $dialMenuAnimation) {
                    ForEach(DialMenuAnimation.allCases) { animation in
                        Text(animation.title).tag(animation)
                    }
                }
            } header: {
                Text("On-Screen HUD")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
