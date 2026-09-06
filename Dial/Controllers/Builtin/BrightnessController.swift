//
//  BrightnessController.swift
//  Dial
//
//  Created by KrLite on 2024/3/21.
//

import Foundation
import SFSafeSymbols
import AppKit

class BrightnessController: BuiltinController {
    static let instance: BrightnessController = .init()
    
    var id: ControllerID = .builtin(.brightness)
    var name: String? = String(localized: .init("Controllers/Default/Brightness: Name", defaultValue: "Brightness"))
    var symbol: SFSymbol = .sunMax
    
    var controllerDescription: ControllerDescription = .init(
        abstraction: .init(localized: .init("Controllers/Builtin/Brightness: Abstraction", defaultValue: """
You can control screen brightness and keyboard backlighting through this controller.
""")),
        
        rotateClockwisely: .init(localized: .init("Controllers/Builtin/Brightness: Rotate Clockwisely", defaultValue: """
Screen brightness up.
""")),
        rotateCounterclockwisely: .init(localized: .init("Controllers/Builtin/Brightness: Rotate Counterclockwisely", defaultValue: """
Screen brightness down.
""")),
        
        press: .init(localized: .init("Controllers/Builtin/Brightness: Press", defaultValue: """
Keyboard backlighting up.
""")),
        doublePress: .init(localized: .init("Controllers/Builtin/Brightness: Double Press", defaultValue: """
Keyboard backlighting down.
""")),
        
        pressAndRotateClockwisely: .init(localized: .init("Controllers/Builtin/Brightness: Press and Rotate Clockwisely", defaultValue: """
Keyboard backlighting up.
""")),
        pressAndRotateCounterclockwisely: .init(localized: .init("Controllers/Builtin/Brightness: Press and Rotate Counterclockwisely", defaultValue: """
Keyboard backlighting down.
"""))
    )
    
    var haptics: Bool = false
    var rotationType: Rotation.RawType = .continuous
    
    func onClick(isDoubleClick: Bool, interval: TimeInterval?, _ callback: SurfaceDial.Callback) {
        if isDoubleClick {
            Input.postAuxKeys([Input.keyIlluminationDown])
        } else {
            Input.postAuxKeys([Input.keyIlluminationUp])
        }
    }
    
    func onRotation(
        rotation: Rotation, totalDegrees: Int,
        buttonState: Hardware.ButtonState, interval: TimeInterval?, duration: TimeInterval,
        _ callback: SurfaceDial.Callback
    ) {
        switch rotation {
        case .continuous(let direction):
            switch (buttonState, direction) {
            case (.released, .clockwise):
                Input.postAuxKeys([Input.keyBrightnessUp])
            case (.released, .counterclockwise):
                Input.postAuxKeys([Input.keyBrightnessDown])
            case (.pressed, .clockwise):
                Input.postAuxKeys([Input.keyIlluminationUp])
            case (.pressed, .counterclockwise):
                Input.postAuxKeys([Input.keyIlluminationDown])
            }
        default:
            break
        }
    }
}

