//
//  ZoomController.swift
//  Dial
//

import Foundation
import SFSafeSymbols

class ZoomController: BuiltinController {
    static let instance: ZoomController = .init()
    
    var id: ControllerID = .builtin(.zoom)
    var name: String? = String(localized: .init("Controllers/Default/Zoom: Name", defaultValue: "Zoom"))
    var symbol: SFSymbol = .magnifyingglass
    
    var controllerDescription: ControllerDescription = .init(
        abstraction: .init(localized: .init("Controllers/Builtin/Zoom: Abstraction", defaultValue: """
You can zoom in and out or reset to actual size.
""")),
        rotateClockwisely: .init(localized: .init("Controllers/Builtin/Zoom: Rotate Clockwisely", defaultValue: """
Zoom in.
""")),
        rotateCounterclockwisely: .init(localized: .init("Controllers/Builtin/Zoom: Rotate Counterclockwisely", defaultValue: """
Zoom out.
""")),
        press: .init(localized: .init("Controllers/Builtin/Zoom: Press", defaultValue: """
Reset zoom to actual size.
"""))
    )
    
    var haptics: Bool = true
    var rotationType: Rotation.RawType = .stepping
    
    func onClick(isDoubleClick: Bool, interval: TimeInterval?, _ callback: SurfaceDial.Callback) {
        if !isDoubleClick {
            Input.key0.post(modifiers: [.command])
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
                Input.keyEquals.post(modifiers: [.command])
            case .counterclockwise:
                Input.keyMinus.post(modifiers: [.command])
            }
            callback.device.buzz()
        default:
            break
        }
    }
    
    func onRelease(_ callback: SurfaceDial.Callback) {
        
    }
}
