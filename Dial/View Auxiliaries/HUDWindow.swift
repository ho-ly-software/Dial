//
//  HUDWindow.swift
//  Dial
//
//  Created by Junie on 2026/07/10.
//

import SwiftUI
import AppKit
import Defaults
import SFSafeSymbols
import Combine

class HUDWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 220),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.level = .screenSaver
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Hide on launch
        self.alphaValue = 0
        self.orderOut(nil)
    }
    
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

class HUDManager {
    static let shared = HUDManager()
    
    private var window: HUDWindow?
    private var fadeOutWorkItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Task { @MainActor in
            self.setupWindow()
            self.observeControllerChanges()
        }
    }
    
    @MainActor
    private func setupWindow() {
        let hudWindow = HUDWindow()
        self.window = hudWindow
    }
    
    @MainActor
    private func observeControllerChanges() {
        Task {
            for await id in Defaults.updates(.currentControllerID) {
                guard let id = id else { continue }
                self.showHUD(for: id.controller)
            }
        }
        
        MainController.instance.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func handleStateChange(_ state: MainController.State) {
        if state.isAgent {
            if let current = Defaults.currentController {
                self.showHUD(for: current)
            }
        } else {
            self.scheduleFadeOut()
        }
    }
    
    @MainActor
    func showHUD(for controller: Controller) {
        guard let window = window else { return }
        
        // Update content
        window.contentView = NSHostingView(
            rootView: HUDContentView(controller: controller)
        )
        
        // Center the window on the active screen containing the mouse cursor
        let mouseLoc = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) }) ?? NSScreen.main ?? NSScreen.screens.first
        
        if let screen = targetScreen {
            let screenRect = screen.frame
            let windowRect = window.frame
            var newOrigin: NSPoint
            
            if Defaults[.dialMenuAppearsAtCursor] {
                let desiredX = mouseLoc.x - windowRect.width / 2
                let desiredY = mouseLoc.y - windowRect.height / 2
                
                let minX = screenRect.minX + 16
                let maxX = screenRect.maxX - windowRect.width - 16
                let minY = screenRect.minY + 16
                let maxY = screenRect.maxY - windowRect.height - 16
                
                newOrigin = NSPoint(
                    x: max(minX, min(maxX, desiredX)),
                    y: max(minY, min(maxY, desiredY))
                )
            } else {
                newOrigin = NSPoint(
                    x: screenRect.origin.x + (screenRect.width - windowRect.width) / 2,
                    y: screenRect.origin.y + (screenRect.height - windowRect.height) / 2
                )
            }
            window.setFrameOrigin(newOrigin)
        }
        
        // Bring to front
        window.orderFront(nil)
        
        // Cancel existing fade out
        fadeOutWorkItem?.cancel()
        
        // Fade in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            window.animator().alphaValue = 1.0
        }
        
        // Schedule fade out only if not in selection mode (Agent Mode)
        if !MainController.instance.isAgent {
            scheduleFadeOut()
        }
    }
    
    @MainActor
    private func scheduleFadeOut() {
        fadeOutWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                self.fadeOut()
            }
        }
        self.fadeOutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)
    }
    
    @MainActor
    private func fadeOut() {
        guard let window = window else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            window.animator().alphaValue = 0.0
        } completionHandler: {
            if window.alphaValue == 0 {
                window.orderOut(nil)
            }
        }
    }
}

struct HUDContentView: View {
    let controller: Controller
    
    @Default(.activatedControllerIDs) var activatedControllerIDs
    @Default(.currentControllerID) var currentControllerID
    @Default(.dialMenuThickness) var dialMenuThickness
    @Default(.dialMenuAnimation) var dialMenuAnimation
    
    private var radius: CGFloat {
        45 + dialMenuThickness.value
    }
    
    private func pointOnTrack(for angleInDegrees: Double, radius: CGFloat) -> (x: CGFloat, y: CGFloat) {
        let radians = angleInDegrees * .pi / 180.0
        let x = radius * CGFloat(sin(radians))
        let y = -radius * CGFloat(cos(radians))
        return (x, y)
    }
    
    var body: some View {
        let activeIndex = activatedControllerIDs.firstIndex(of: currentControllerID ?? .builtin(.scroll)) ?? 0
        let count = activatedControllerIDs.count
        let activeAngle = count > 0 ? (360.0 * Double(activeIndex) / Double(count)) : 0.0
        let activePoint = pointOnTrack(for: activeAngle, radius: radius)
        
        ZStack {
            // Subtle track stroke
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                .frame(width: radius * 2, height: radius * 2)
            
            // Highlight sector circle
            if count > 0 {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .overlay(
                        Circle().stroke(Color.accentColor, lineWidth: 1.5)
                    )
                    .frame(width: 34, height: 34)
                    .offset(x: activePoint.x, y: activePoint.y)
                    .animation(dialMenuAnimation.value, value: activeAngle)
            }
            
            // Outer Icons distributed along the track
            ForEach(0..<count, id: \.self) { index in
                let id = activatedControllerIDs[index]
                let angle = 360.0 * Double(index) / Double(count)
                let point = pointOnTrack(for: angle, radius: radius)
                
                Image(systemSymbol: id.controller.symbol)
                    .font(.system(size: 16, weight: index == activeIndex ? .semibold : .regular))
                    .foregroundColor(index == activeIndex ? .primary : .secondary)
                    .frame(width: 32, height: 32)
                    .offset(x: point.x, y: point.y)
            }
            
            // Center Area
            VStack(spacing: 8) {
                Image(systemSymbol: controller.symbol)
                    .font(.system(size: 48, weight: .regular))
                    .foregroundColor(.primary)
                
                Text(controller.name ?? controllerNamePlaceholder)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 110)
            }
        }
        .frame(width: 220, height: 220)
        .hudBackground()
    }
}

extension View {
    @ViewBuilder
    func hudBackground() -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(in: Circle())
                .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 1))
        } else {
            self.background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 1))
        }
    }
}
