//
//  DialApp.swift
//  Dial
//
//  Created by KrLite on 2024/3/20.
//

import SwiftUI
import MenuBarExtraAccess
import SFSafeSymbols

var dial: SurfaceDial = .init()

var controllerNamePlaceholder: String = .init(localized: .init("Controller Name Placeholder", defaultValue: "New Controller"))

func notifyTaskStart(_ message: String, _ sender: Any? = nil) {
    print("!!! Task started: \(message) !!!", terminator: "")
    if let sender {
        print(" (\(String(describing: type(of: sender))))", terminator: "")
    }
    print()
}

@main
struct DialApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var isMenuBarItemPresented: Bool = false
    
    var body: some Scene {
        MenuBarExtra("Dial", systemImage: SFSymbol.hockeyPuck.rawValue) {
            MenuBarMenuView()
        }
        .menuBarExtraStyle(.menu)
    }
}
