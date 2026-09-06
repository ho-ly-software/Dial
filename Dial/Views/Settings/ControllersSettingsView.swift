//
//  ControllersSettingsView.swift
//  Dial
//
//  Created by KrLite on 2024/3/30.
//

import SwiftUI
import Defaults
import SFSafeSymbols

struct ControllersSettingsView: View {
    @Default(.activatedControllerIDs) var activatedControllerIDs
    @Default(.inactivatedControllerIDs) var inactivatedControllerIDs
    @Default(.currentControllerID) var currentControllerID
    
    @State private var selectedID: ControllerID?
    @State private var showingLimitAlert: Bool = false
    
    private var availableBuiltinsToAdd: [ControllerID.Builtin] {
        ControllerID.Builtin.availableCases.filter { builtin in
            !activatedControllerIDs.contains(.builtin(builtin)) &&
            !inactivatedControllerIDs.contains(.builtin(builtin))
        }
    }
    
    var body: some View {
        HSplitView {
            // Left sidebar: Controller List
            VStack(spacing: 0) {
                List(selection: $selectedID) {
                    Section {
                        ForEach(activatedControllerIDs, id: \.self) { id in
                            controllerRow(for: id, isActivated: true)
                                .tag(id)
                        }
                        .onMove(perform: moveActivatedControllers)
                    } header: {
                        HStack {
                            Text("Active (\(activatedControllerIDs.count)/\(Defaults.maxControllersCount))")
                            Spacer()
                        }
                    }
                    
                    if !inactivatedControllerIDs.isEmpty {
                        Section("Inactive") {
                            ForEach(inactivatedControllerIDs, id: \.self) { id in
                                controllerRow(for: id, isActivated: false)
                                    .tag(id)
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                
                Divider()
                
                // Bottom control bar
                HStack(spacing: 4) {
                    Menu {
                        Button {
                            let newSettings = ShortcutsController.Settings()
                            let newID = ControllerID.shortcuts(newSettings)
                            if activatedControllerIDs.count < Defaults.maxControllersCount {
                                Defaults[.activatedControllerIDs].append(newID)
                            } else {
                                Defaults[.inactivatedControllerIDs].append(newID)
                            }
                            selectedID = newID
                        } label: {
                            Label("New Custom Controller", systemSymbol: .plus)
                        }
                        
                        if !availableBuiltinsToAdd.isEmpty {
                            Divider()
                            ForEach(availableBuiltinsToAdd, id: \.self) { builtin in
                                Button {
                                    let id = ControllerID.builtin(builtin)
                                    Defaults.appendBuiltinController(id: builtin)
                                    selectedID = id
                                } label: {
                                    Label(builtin.controller.name ?? "", systemSymbol: builtin.controller.symbol)
                                }
                            }
                        }
                    } label: {
                        Image(systemSymbol: .plus)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 24, height: 24)
                    
                    Button {
                        deleteSelectedController()
                    } label: {
                        Image(systemSymbol: .minus)
                    }
                    .buttonStyle(.borderless)
                    .disabled(selectedID == nil || isSelectedBuiltinActive)
                    .help("Delete Controller")
                    
                    Button {
                        duplicateSelectedController()
                    } label: {
                        Image(systemSymbol: .plusSquareOnSquare)
                    }
                    .buttonStyle(.borderless)
                    .disabled(selectedID == nil || selectedID?.isBuiltin == true)
                    .help("Duplicate Controller")
                    
                    Spacer()
                    
                    Button {
                        moveSelectedController(by: -1)
                    } label: {
                        Image(systemSymbol: .chevronUp)
                    }
                    .buttonStyle(.borderless)
                    .disabled(!canMoveSelectedUp)
                    .help("Move Up")
                    
                    Button {
                        moveSelectedController(by: 1)
                    } label: {
                        Image(systemSymbol: .chevronDown)
                    }
                    .buttonStyle(.borderless)
                    .disabled(!canMoveSelectedDown)
                    .help("Move Down")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(nsColor: .windowBackgroundColor))
            }
            .frame(minWidth: 220, maxWidth: 300)
            
            // Right detail view
            Group {
                if let selectedID {
                    ControllerDetailView(controllerID: selectedID)
                } else {
                    VStack(spacing: 12) {
                        Image(systemSymbol: .sliderVertical3)
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Select a controller to view its details")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 320)
        }
        .onAppear {
            if selectedID == nil {
                selectedID = activatedControllerIDs.first ?? inactivatedControllerIDs.first
            }
        }
        .alert("Controller Limit Reached", isPresented: $showingLimitAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can have up to \(Defaults.maxControllersCount) active controllers at a time.")
        }
    }
    
    @ViewBuilder
    private func controllerRow(for id: ControllerID, isActivated: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemSymbol: id.controller.symbol)
                .frame(width: 18)
            
            Text(id.controller.name ?? controllerNamePlaceholder)
                .lineLimit(1)
            
            Spacer()
            
            Button {
                toggleActivation(for: id)
            } label: {
                Image(systemSymbol: isActivated ? .checkmarkCircleFill : .circle)
                    .foregroundColor(isActivated ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            .help(isActivated ? "Deactivate controller" : "Activate controller")
        }
    }
    
    private func toggleActivation(for id: ControllerID) {
        if activatedControllerIDs.contains(id) {
            Defaults[.activatedControllerIDs].replace([id], with: [])
            Defaults[.inactivatedControllerIDs].append(id)
            if currentControllerID == id {
                Defaults[.currentControllerID] = Defaults[.activatedControllerIDs].first
            }
        } else {
            if activatedControllerIDs.count >= Defaults.maxControllersCount {
                showingLimitAlert = true
                return
            }
            Defaults[.inactivatedControllerIDs].replace([id], with: [])
            Defaults[.activatedControllerIDs].append(id)
        }
    }
    
    private func moveActivatedControllers(from source: IndexSet, to destination: Int) {
        var updated = activatedControllerIDs
        updated.move(fromOffsets: source, toOffset: destination)
        Defaults[.activatedControllerIDs] = updated
    }
    
    private var isSelectedBuiltinActive: Bool {
        guard let selectedID else { return false }
        return selectedID.isBuiltin && activatedControllerIDs.contains(selectedID)
    }
    
    private var canMoveSelectedUp: Bool {
        guard let selectedID, let index = activatedControllerIDs.firstIndex(of: selectedID) else { return false }
        return index > 0
    }
    
    private var canMoveSelectedDown: Bool {
        guard let selectedID, let index = activatedControllerIDs.firstIndex(of: selectedID) else { return false }
        return index < activatedControllerIDs.count - 1
    }
    
    private func moveSelectedController(by offset: Int) {
        guard let selectedID, let index = activatedControllerIDs.firstIndex(of: selectedID) else { return }
        let newIndex = index + offset
        guard (0..<activatedControllerIDs.count).contains(newIndex) else { return }
        
        var updated = activatedControllerIDs
        updated.swapAt(index, newIndex)
        Defaults[.activatedControllerIDs] = updated
    }
    
    private func duplicateSelectedController() {
        guard let selectedID else { return }
        if case .shortcuts(let settings) = selectedID {
            let duplicated = ShortcutsController.Settings(
                name: (settings.name ?? "") + " Copy",
                symbol: settings.symbol,
                haptics: settings.haptics,
                physicalDirection: settings.physicalDirection,
                alternativeDirection: settings.alternativeDirection,
                rotationType: settings.rotationType,
                shortcuts: settings.shortcuts
            )
            let newID = ControllerID.shortcuts(duplicated)
            Defaults[.inactivatedControllerIDs].append(newID)
            self.selectedID = newID
        }
    }
    
    private func deleteSelectedController() {
        guard let selectedID else { return }
        if selectedID.isBuiltin {
            // Inactivate builtin
            if activatedControllerIDs.contains(selectedID) {
                Defaults[.activatedControllerIDs].replace([selectedID], with: [])
                Defaults[.inactivatedControllerIDs].append(selectedID)
            }
        } else {
            // Delete custom controller
            Defaults.removeController(id: selectedID)
            self.selectedID = activatedControllerIDs.first ?? inactivatedControllerIDs.first
        }
    }
}
