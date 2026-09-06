//
//  Hardware.swift
//  Dial
//
//  Created by KrLite on 2024/3/21.
//

import Foundation
import Defaults
import IOKit.hid

protocol InputHandler {
    func onButtonStateChanged(_ buttonState: Hardware.ButtonState)
    func onRotation(_ direction: Direction, _ buttonState: Hardware.ButtonState)
}

@Observable class Hardware {
    // MARK: Product identifiers for Surface Dials
    static let vendorId: UInt16 = 0x045E
    static let productId: UInt16 = 0x091B
    
    var connectionStatus: ConnectionStatus = .disconnected
    var buttonState: ButtonState = .released
    var lastButtonState: ButtonState = .released
    var inputHandler: InputHandler?
    
    private var manager: IOHIDManager?
    private var device: IOHIDDevice?
    
    deinit {
        stop()
    }
}

extension Hardware {
    enum ConnectionStatus {
        case connected(String)
        case disconnected
        
        var isConnected: Bool {
            switch self {
            case .connected(_):
                true
            case .disconnected:
                false
            }
        }
    }
    
    enum HapticsMode: UInt8 {
        case none = 0x02
        case buzz = 0x03
        case continuous = 0x04
    }
    
    enum ButtonState {
        case pressed
        case released
    }
}

extension Hardware {
    var isConnected: Bool {
        device != nil
    }
    
    var manufacturer: String {
        guard let device = self.device else { return "" }
        return (IOHIDDeviceGetProperty(device, kIOHIDManufacturerKey as CFString) as? String) ?? ""
    }
    
    var serialNumber: String {
        guard let device = self.device else { return "" }
        return (IOHIDDeviceGetProperty(device, kIOHIDSerialNumberKey as CFString) as? String) ?? ""
    }
    
    func initSensitivity(autoTriggers haptics: Bool) {
        guard isConnected, let device = self.device else { return }
        let autoTriggers = haptics && !MainController.instance.isAgent
        let steps_lo = 360 & 0xff
        let steps_hi = (360 >> 8) & 0xff
        var buf: [UInt8] = []
        
        buf.append(0x01) // Report ID
        buf.append(UInt8(steps_lo))
        buf.append(UInt8(steps_hi))
        buf.append(0x00) // Repeat count
        buf.append(autoTriggers ? 0x03 : 0x02) // Buzz style
        buf.append(0x00) // Waveform cutoff time
        buf.append(0x00) // Retrigger period (lo)
        buf.append(0x00) // Retrigger period (hi)
        
        buf.withUnsafeBufferPointer { ptr in
            guard let baseAddress = ptr.baseAddress else { return }
            IOHIDDeviceSetReport(device, kIOHIDReportTypeFeature, CFIndex(buf[0]), baseAddress, buf.count)
        }
    }
    
    func buzz(_ repeatCount: UInt8 = 1) {
        guard repeatCount > 0 else { return }
        
        if Defaults[.globalHapticsEnabled], isConnected, let device = self.device {
            var buf: [UInt8] = []
            
            buf.append(0x01) // Report ID
            buf.append(repeatCount - 1) // Repeat count
            buf.append(HapticsMode.buzz.rawValue) // Buzz
            buf.append(0x00) // Retrigger period (lo)
            buf.append(0x00) // Retrigger period (hi)
            
            buf.withUnsafeBufferPointer { ptr in
                guard let baseAddress = ptr.baseAddress else { return }
                IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, CFIndex(buf[0]), baseAddress, buf.count)
            }
        }
    }
    
    func handleInputReport(reportID: UInt32, report: UnsafeMutablePointer<UInt8>, length: CFIndex) {
        guard length > 0 else { return }
        let buffer = UnsafeBufferPointer(start: report, count: Int(length))
        
        var buttonState: ButtonState?
        var direction: Direction?
        
        if buffer.count >= 4 && buffer[0] == 0x01 {
            buttonState = (buffer[1] & 0x01 == 0x01) ? .pressed : .released
            let hasRotation = buffer[2] != 0x00
            if hasRotation {
                direction = switch buffer[3] {
                case 0x00, 0x01:
                    .clockwise
                case 0xff:
                    .counterclockwise
                default:
                    nil
                }
            }
        } else if buffer.count >= 3 && (reportID == 1 || buffer[0] <= 1) {
            buttonState = (buffer[0] & 0x01 == 0x01) ? .pressed : .released
            let hasRotation = buffer[1] != 0x00
            if hasRotation {
                direction = switch buffer[2] {
                case 0x00, 0x01:
                    .clockwise
                case 0xff:
                    .counterclockwise
                default:
                    nil
                }
            }
        }
        
        guard let buttonState else { return }
        let adjustedDirection = direction?.multiply(Defaults[.globalDirection])
        
        switch buttonState {
        case .pressed where lastButtonState == .released:
            inputHandler?.onButtonStateChanged(.pressed)
        case .released where lastButtonState == .pressed:
            inputHandler?.onButtonStateChanged(.released)
        default:
            break
        }
        
        if let adjustedDirection {
            inputHandler?.onRotation(adjustedDirection, buttonState)
        }
        
        self.buttonState = buttonState
        self.lastButtonState = buttonState
    }
}

extension Hardware {
    func start() {
        guard manager == nil else { return }
        
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = manager
        
        let matchingDict: [String: Any] = [
            kIOHIDVendorIDKey: Int(Hardware.vendorId),
            kIOHIDProductIDKey: Int(Hardware.productId)
        ]
        IOHIDManagerSetDeviceMatching(manager, matchingDict as CFDictionary)
        
        let context = Unmanaged.passUnretained(self).toOpaque()
        
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, result, sender, device in
            guard let context = context else { return }
            let hardware = Unmanaged<Hardware>.fromOpaque(context).takeUnretainedValue()
            hardware.deviceMatched(device)
        }, context)
        
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, result, sender, device in
            guard let context = context else { return }
            let hardware = Unmanaged<Hardware>.fromOpaque(context).takeUnretainedValue()
            hardware.deviceRemoved(device)
        }, context)
        
        IOHIDManagerRegisterInputReportCallback(manager, { context, result, sender, type, reportID, report, reportLength in
            guard let context = context else { return }
            let hardware = Unmanaged<Hardware>.fromOpaque(context).takeUnretainedValue()
            hardware.handleInputReport(reportID: reportID, report: report, length: reportLength)
        }, context)
        
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        if openResult != kIOReturnSuccess {
            print("IOHIDManagerOpen failed with error: \(openResult)")
        }
    }
    
    func stop() {
        if let manager {
            IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            self.manager = nil
        }
        self.device = nil
        self.connectionStatus = .disconnected
        self.buttonState = .released
        self.lastButtonState = .released
    }
    
    private func deviceMatched(_ device: IOHIDDevice) {
        self.device = device
        let serial = (IOHIDDeviceGetProperty(device, kIOHIDSerialNumberKey as CFString) as? String) ?? ""
        print("Connected to device \(serial)!")
        self.connectionStatus = .connected(serial)
        
        buzz(3)
        initSensitivity(autoTriggers: Defaults.currentController?.autoTriggers ?? false)
    }
    
    private func deviceRemoved(_ device: IOHIDDevice) {
        if self.device == device {
            print("Device disconnected.")
            self.device = nil
            self.connectionStatus = .disconnected
            self.buttonState = .released
            self.lastButtonState = .released
        }
    }
}

extension Hardware {
    var callback: Callback {
        Callback(self)
    }
    
    struct Callback {
        private var hardware: Hardware
        
        init(_ device: Hardware) {
            self.hardware = device
        }
        
        func buzz(_ repeatCount: UInt8 = 1) {
            hardware.buzz(repeatCount)
        }
        
        func initSensitivity(autoTriggers haptics: Bool) {
            hardware.initSensitivity(autoTriggers: haptics)
        }
    }
}

