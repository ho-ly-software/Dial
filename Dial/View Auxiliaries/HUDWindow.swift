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

class HUDWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 180, height: 180),
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
    }
    
    @MainActor
    func showHUD(for controller: Controller) {
        guard let window = window else { return }
        
        // Update content
        window.contentView = NSHostingView(
            rootView: HUDContentView(controller: controller)
        )
        
        // Center the window on the current active screen
        if let screen = NSScreen.main {
            let screenRect = screen.frame
            let windowRect = window.frame
            let newOrigin = NSPoint(
                x: screenRect.origin.x + (screenRect.width - windowRect.width) / 2,
                y: screenRect.origin.y + (screenRect.height - windowRect.height) / 5
            )
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
        
        // Schedule fade out
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
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemSymbol: controller.symbol)
                .font(.system(size: 64, weight: .regular))
                .foregroundColor(.primary)
            
            Text(controller.name ?? controllerNamePlaceholder)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(24)
        .frame(width: 180, height: 180)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
