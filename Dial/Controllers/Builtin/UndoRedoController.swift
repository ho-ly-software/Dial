//
//  UndoRedoController.swift
//  Dial
//

import Foundation
import SFSafeSymbols

class UndoRedoController: BuiltinController {
    static let instance: UndoRedoController = .init()
    
    var id: ControllerID = .builtin(.undoRedo)
    var name: String? = String(localized: .init("Controllers/Default/UndoRedo: Name", defaultValue: "Undo / Redo"))
    var symbol: SFSymbol = .arrowUturnBackward
    
    var controllerDescription: ControllerDescription = .init(
        abstraction: .init(localized: .init("Controllers/Builtin/UndoRedo: Abstraction", defaultValue: """
You can perform undo and redo actions.
""")),
        rotateClockwisely: .init(localized: .init("Controllers/Builtin/UndoRedo: Rotate Clockwisely", defaultValue: """
Redo.
""")),
        rotateCounterclockwisely: .init(localized: .init("Controllers/Builtin/UndoRedo: Rotate Counterclockwisely", defaultValue: """
Undo.
""")),
        press: .init(localized: .init("Controllers/Builtin/UndoRedo: Press", defaultValue: """
Undo.
"""))
    )
    
    var haptics: Bool = true
    var rotationType: Rotation.RawType = .stepping
    
    func onClick(isDoubleClick: Bool, interval: TimeInterval?, _ callback: SurfaceDial.Callback) {
        if !isDoubleClick {
            Input.keyZ.post(modifiers: [.command])
            callback.device.buzz()
        }
    }
    
    func onRotation(
        rotation: Rotation, totalDegrees: Int,
        buttonState: Hardware.ButtonState, interval: TimeInterval?, duration: TimeInterval,
        _ callback: SurfaceDial.Callback
    ) {
        switch rotation {
        case .stepping(let direction):
            switch direction {
            case .clockwise:
                Input.keyZ.post(modifiers: [.command, .shift])
            case .counterclockwise:
                Input.keyZ.post(modifiers: [.command])
            }
            callback.device.buzz()
        default:
            break
        }
    }
    
    func onRelease(_ callback: SurfaceDial.Callback) {
        
    }
}
