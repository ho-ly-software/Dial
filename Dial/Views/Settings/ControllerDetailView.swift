//
//  ControllerDetailView.swift
//  Dial
//
//  Created by KrLite on 2024/3/30.
//

import SwiftUI
import Defaults
import SFSafeSymbols

struct ControllerDetailView: View {
    var controllerID: ControllerID
    
    @State private var settings: ShortcutsController.Settings?
    @State private var isSymbolPickerPresented: Bool = false
    
    var body: some View {
        Group {
            switch controllerID {
            case .builtin(let builtin):
                builtinDetailView(builtin: builtin)
            case .shortcuts(_):
                if let settings = Binding($settings) {
                    customDetailView(settings: settings)
                } else {
                    ProgressView()
                }
            }
        }
        .onAppear {
            loadSettings()
        }
        .onChange(of: controllerID) { _, _ in
            loadSettings()
        }
    }
    
    private func loadSettings() {
        if case .shortcuts(let s) = controllerID {
            // Find current persisted settings if updated in Defaults
            if let found = Defaults.allControllerIDs.compactMap({ id -> ShortcutsController.Settings? in
                if case .shortcuts(let set) = id, set.id == s.id { return set }
                return nil
            }).first {
                self.settings = found
            } else {
                self.settings = s
            }
        } else {
            self.settings = nil
        }
    }
    
    private func saveSettings(_ newSettings: ShortcutsController.Settings) {
        Defaults.saveController(settings: newSettings)
    }
    
    @ViewBuilder
    private func customDetailView(settings: Binding<ShortcutsController.Settings>) -> some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    Button {
                        isSymbolPickerPresented = true
                    } label: {
                        Image(systemSymbol: settings.wrappedValue.symbol)
                            .font(.system(size: 24))
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(nsColor: .controlBackgroundColor))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $isSymbolPickerPresented) {
                        SymbolPickerView(selectedSymbol: Binding(
                            get: { settings.wrappedValue.symbol },
                            set: {
                                settings.wrappedValue.symbol = $0
                                saveSettings(settings.wrappedValue)
                            }
                        ))
                    }
                    
                    TextField("Controller Name", text: Binding(
                        get: { settings.wrappedValue.name ?? "" },
                        set: {
                            settings.wrappedValue.name = $0.isEmpty ? nil : $0
                            saveSettings(settings.wrappedValue)
                        }
                    ), prompt: Text(controllerNamePlaceholder))
                    .textFieldStyle(.roundedBorder)
                }
            } header: {
                Text("Information")
            }
            
            Section {
                Picker("Rotation Mode", selection: Binding(
                    get: { settings.wrappedValue.rotationType },
                    set: {
                        settings.wrappedValue.rotationType = $0
                        saveSettings(settings.wrappedValue)
                    }
                )) {
                    ForEach(Rotation.RawType.allCases) { type in
                        Text(type.name).tag(type)
                    }
                }
                
                Toggle("Haptic Feedback", isOn: Binding(
                    get: { settings.wrappedValue.haptics },
                    set: {
                        settings.wrappedValue.haptics = $0
                        saveSettings(settings.wrappedValue)
                    }
                ))
                
                Toggle("Invert Rotation Direction", isOn: Binding(
                    get: { settings.wrappedValue.alternativeDirection },
                    set: {
                        settings.wrappedValue.alternativeDirection = $0
                        saveSettings(settings.wrappedValue)
                    }
                ))
            } header: {
                Text("Behavior")
            }
            
            Section {
                HStack {
                    Text("Rotate Clockwise")
                    Spacer()
                    ShortcutRecorderField(shortcut: Binding(
                        get: { settings.wrappedValue.shortcuts.rotate.clockwisely },
                        set: {
                            settings.wrappedValue.shortcuts.rotate.clockwisely = $0
                            saveSettings(settings.wrappedValue)
                        }
                    ))
                }
                
                HStack {
                    Text("Rotate Counterclockwise")
                    Spacer()
                    ShortcutRecorderField(shortcut: Binding(
                        get: { settings.wrappedValue.shortcuts.rotate.counterclockwisely },
                        set: {
                            settings.wrappedValue.shortcuts.rotate.counterclockwisely = $0
                            saveSettings(settings.wrappedValue)
                        }
                    ))
                }
            } header: {
                Text("Rotation Shortcuts")
            }
            
            Section {
                HStack {
                    Text("Press & Rotate Clockwise")
                    Spacer()
                    ShortcutRecorderField(shortcut: Binding(
                        get: { settings.wrappedValue.shortcuts.pressAndRotate.clockwisely },
                        set: {
                            settings.wrappedValue.shortcuts.pressAndRotate.clockwisely = $0
                            saveSettings(settings.wrappedValue)
                        }
                    ))
                }
                
                HStack {
                    Text("Press & Rotate Counterclockwise")
                    Spacer()
                    ShortcutRecorderField(shortcut: Binding(
                        get: { settings.wrappedValue.shortcuts.pressAndRotate.counterclockwisely },
                        set: {
                            settings.wrappedValue.shortcuts.pressAndRotate.counterclockwisely = $0
                            saveSettings(settings.wrappedValue)
                        }
                    ))
                }
            } header: {
                Text("Pressed Rotation Shortcuts")
            }
            
            Section {
                HStack {
                    Text("Single Press")
                    Spacer()
                    ShortcutRecorderField(shortcut: Binding(
                        get: { settings.wrappedValue.shortcuts.press },
                        set: {
                            settings.wrappedValue.shortcuts.press = $0
                            saveSettings(settings.wrappedValue)
                        }
                    ))
                }
                
                HStack {
                    Text("Double Press")
                    Spacer()
                    ShortcutRecorderField(shortcut: Binding(
                        get: { settings.wrappedValue.shortcuts.doublePress },
                        set: {
                            settings.wrappedValue.shortcuts.doublePress = $0
                            saveSettings(settings.wrappedValue)
                        }
                    ))
                }
            } header: {
                Text("Click Shortcuts")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    @ViewBuilder
    private func builtinDetailView(builtin: ControllerID.Builtin) -> some View {
        let controller = builtin.controller
        
        Form {
            Section {
                HStack(spacing: 12) {
                    Image(systemSymbol: controller.symbol)
                        .font(.system(size: 24))
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(controller.name ?? "")
                            .font(.headline)
                        Text("Built-in System Controller")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Controller")
            }
            
            if let description = (controller as? BuiltinController)?.controllerDescription {
                Section {
                    Text(description.abstraction)
                        .font(.callout)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Description")
                }
                
                Section {
                    LabeledContent("Rotate Clockwise", value: description.rotateClockwisely)
                    LabeledContent("Rotate Counterclockwise", value: description.rotateCounterclockwisely)
                    LabeledContent("Press", value: description.press)
                    LabeledContent("Double Press", value: description.doublePress)
                    if !description.pressAndRotateClockwisely.isEmpty {
                        LabeledContent("Press & Rotate Clockwise", value: description.pressAndRotateClockwisely)
                    }
                    if !description.pressAndRotateCounterclockwisely.isEmpty {
                        LabeledContent("Press & Rotate Counterclockwise", value: description.pressAndRotateCounterclockwisely)
                    }
                } header: {
                    Text("Default Actions")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
