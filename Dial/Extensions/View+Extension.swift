//
//  View+Extension.swift
//  Dial
//
//  Created by KrLite on 2024/3/23.
//

import Foundation
import SwiftUI
import AppKit

extension View {
    func copyToClipboard(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
    
    func or(condition: Bool, _ another: () -> Self) -> Self {
        condition ? another() : self
    }
    
    @ViewBuilder
    func orSomeView(condition: Bool, _ another: () -> some View) -> some View {
        if condition {
            another()
        } else {
            self
        }
    }
    
    @ViewBuilder
    func `if`(
        condition: Bool,
        _ trueExpression: (Self) -> some View,
        falseExpression: (Self) -> some View
    ) -> some View {
        if condition {
            trueExpression(self)
        } else {
            falseExpression(self)
        }
    }
    
    @ViewBuilder
    func `if`(
        condition: Bool,
        _ expression: (Self) -> some View
    ) -> some View {
        `if`(condition: condition, expression) { view in
            view
        }
    }
    
    @ViewBuilder
    func possibleKeyboardShortcut(
        _ key: KeyEquivalent?,
        modifiers: EventModifiers = .command,
        localization: KeyboardShortcut.Localization = .automatic
    ) -> some View {
        if let key {
            self.keyboardShortcut(key, modifiers: modifiers, localization: localization)
        } else {
            self
        }
    }
}
