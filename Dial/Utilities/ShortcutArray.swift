//
//  ShortcutArray.swift
//  Dial
//
//  Created by KrLite on 2024/3/21.
//

import Foundation
import AppKit
import Defaults

extension NSEvent.ModifierFlags: Codable {
    // Make it codable
}

struct ShortcutArray: Codable, Defaults.Serializable {
    var modifiers: NSEvent.ModifierFlags
    
    var keys: Set<Input>
    
    var display: String {
        var modifierGlyphs: [String] = []
        if modifiers.contains(.control) { modifierGlyphs.append("⌃") }
        if modifiers.contains(.option) { modifierGlyphs.append("⌥") }
        if modifiers.contains(.shift) { modifierGlyphs.append("⇧") }
        if modifiers.contains(.command) { modifierGlyphs.append("⌘") }
        if modifiers.contains(.capsLock) { modifierGlyphs.append("⇪") }
        if modifiers.contains(.function) { modifierGlyphs.append("fn") }
        
        let keyNames = sortedKeys.map { $0.name }
        if modifierGlyphs.isEmpty {
            return keyNames.joined(separator: " ")
        } else if keyNames.isEmpty {
            return modifierGlyphs.joined()
        } else {
            return (modifierGlyphs.joined() + " " + keyNames.joined(separator: " ")).trimmingCharacters(in: .whitespaces)
        }
    }
    
    var isEmpty: Bool {
        keys.isEmpty && modifiers.isEmpty
    }
    
    init(
        modifiers: NSEvent.ModifierFlags = [],
        keys: Set<Input> = Set()
    ) {
        self.modifiers = modifiers
        self.keys = keys
    }
    
    func post() {
        Input.postKeys(keys, modifiers: modifiers)
    }
}

extension ShortcutArray: Equatable {
    // Make it equatable
}

extension ShortcutArray {
    var sortedKeys: [Input] {
        keys.sorted(by: >)
    }
}

extension ShortcutArray {
    struct DirectionBased: Codable {
        var clockwisely: ShortcutArray
        var counterclockwisely: ShortcutArray
        
        var isAllEmpty: Bool {
            clockwisely.isEmpty && counterclockwisely.isEmpty
        }
        
        func from(_ direction: Direction) -> ShortcutArray {
            switch direction {
            case .clockwise:
                clockwisely
            case .counterclockwise:
                counterclockwisely
            }
        }
    }
}
