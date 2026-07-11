# Dial

###### Your Surface Dial on Mac.

> [!WARNING]
> This project is currently a work in progress.

> [!NOTE]
> This project is based on [MacDial](https://github.com/andreasjhkarlsson/mac-dial), reimagined with a modern, native SwiftUI user interface, improved haptic feedback, and a highly customizable controller architecture to maximize workflow efficiency.

---

Dial is a native macOS companion application that integrates the **Microsoft Surface Dial** seamlessly into macOS. By leveraging low-level USB/Bluetooth HID reports and macOS Accessibility APIs, Dial transforms a physical dial into a powerful productivity interface, boosting task efficiency and user ergonomics.

---

## Key Features

- **Built-in Controllers**:
  - **Scroll**: Pixel-perfect scroll-wheel emulation and middle-mouse button clicks.
  - **Playback**: System-wide media control (Play/Pause, Mute, Volume Up/Down, and Media Seek).
  - **Brightness**: Real-time screen brightness adjustments and keyboard backlight toggle/level controls.
  - **Zoom**: Precise stepping-based zoom-in and zoom-out with single-click reset to actual size.
  - **Undo / Redo**: High-precision stepping-based undo and redo actions.
- **On-Screen Radial Menu (HUD)**: A modern, circular radial selection menu mimicking the original Microsoft Surface Dial's off-screen capabilities menu.
  - Interactive outer ring showing all active controllers distributed symmetrically.
  - Smoothly animated highlight circle that slides dynamically along the ring to select a controller.
  - Support for infinite wrap-around cycling of controllers in both directions.
  - Sticky HUD visibility pinned active as long as the dial is physically held down (Agent Mode), initiating the fade-out timer only after physical release.
  - Adaptive positioning to center the HUD directly under the mouse cursor when enabled.
  - Liquid Glass material support using SwiftUI's native `.glassEffect(in: Circle())` on macOS 26 and macOS 27, falling back gracefully to `.ultraThinMaterial` on older macOS versions.
- **Custom Shortcut Mapper**: Create bespoke dial profiles. Map clockwise/counterclockwise rotation, pressed rotation, single click, and double click to any combination of keyboard shortcuts.
- **Physical Feedback Integration**: Custom haptic feedback patterns (vibrations and buzzes) delivered directly to the physical device.
- **Modern Native UI**: A sleek, lightweight status bar menu with onboarding tips (using TipKit), quick-access toggles, and dedicated customizable preferences for the "On-Screen Dial Menu" (including toggle for cursor positioning, custom menu thickness, and adjustable menu transition animation styles).
- **Universal Architecture**: Built for both Apple Silicon (`arm64`) and Intel (`x86_64`) Macs.

---

## Architecture & Codebase Tour

The Dial codebase is structured to maximize performance, reliability, and modularity. Here is an overview of the core components:

```
Dial
├── Device/
│   ├── Hardware.swift         # Low-level HIDAPI wrapper & HID report parser
│   └── SurfaceDial.swift      # Device interaction coordinator & event router
├── Controllers/
│   ├── Controller.swift       # Protocols, IDs, and lifecycle hooks
│   ├── Builtin/               # Built-in controller implementations
│   │   ├── MainController.swift
│   │   ├── ScrollController.swift
│   │   ├── PlaybackController.swift
│   │   ├── BrightnessController.swift
│   │   ├── ZoomController.swift
│   │   └── UndoRedoController.swift
│   └── ShortcutsController.swift # Dynamic user-defined shortcut profile evaluator
├── Utilities/
│   ├── Input.swift            # CGEvent virtual keyboard & mouse event generation
│   ├── PermissionsManager.swift # macOS Accessibility permissions request utility
│   └── ShortcutArray.swift    # Shortcut array storage & dispatcher
└── Menu Bar/
    └── MenuBarMenuView.swift  # SwiftUI menu-bar interface
```

### Low-Level Device Interaction (`Device/`)
- **`Hardware.swift`**: This class directly communicates with the Microsoft Surface Dial (`Vendor ID: 0x045E`, `Product ID: 0x091B`) via the C-based `hidapi` library. It spawns a background polling thread to read raw input reports. It parses report ID `0x01` (retrieving button press/release, rotation detection, and directional delta) and writes output reports to trigger precise haptic sensations (e.g. configuring rotation tick sensitivity or firing physical vibrations).
- **`SurfaceDial.swift`**: Serves as the primary coordinator. It subscribes to low-level hardware changes and translates raw state changes into higher-level logical events (e.g., long-press "Agent Mode" transitions, double clicks, and calibrated rotational ticks).

### The Controller Framework (`Controllers/`)
The app operates on an extensible **Controller** paradigm, where each physical action is dispatched to an active logical controller:
- **`Controller.swift`**: Defines the `Controller` protocol. A controller can process clicks, rotation steps/ticks, and release events.
- **Agent Mode (`MainController.swift`)**: When a user presses and holds the Surface Dial, it enters **Agent Mode**. In this mode, rotating the dial dynamically cycles through your active list of controllers, allowing on-the-fly context switching with immediate haptic buzz confirmation.
- **Built-in Controllers**:
  - **`ScrollController`**: Simulates smooth trackpad/mouse scroll wheel movements via `CGEvent` and routes middle clicks at the cursor.
  - **`PlaybackController`**: Controls Apple system audio. Pressed rotation changes volume incrementally (`.shift` + `.option` for micro-adjustments), while released rotation performs arrow-key media seeks.
  - **`BrightnessController`**: Pressed rotation modifies display brightness; standard rotation adjusts keyboard illumination level.
  - **`ZoomController`**: Emulates high-precision zooming (clockwise zoom-in, counterclockwise zoom-out) and resets zoom level to 100% on a single click.
  - **`UndoRedoController`**: Facilitates stepping-based clockwise redo and counterclockwise undo actions with single-click undo.
- **Custom Mapping (`ShortcutsController.swift`)**: Dynamically evaluates user-defined profiles, invoking serializable sequences of virtual keystrokes saved on a per-direction or per-click basis.

### Virtual Input Dispatcher (`Utilities/Input.swift`)
Posts raw keyboard and mouse events globally using the CoreGraphics framework (`CGEvent`). It includes a comprehensive map of macOS virtual keycodes and utilizes Apple's private system-defined event subtype `8` to dispatch hardware-level media controls (mute, play, brightness, keyboard illumination) without target-app focus requirements.

### State & Configuration Persistence (`Extensions/`)
Uses the lightweight `Defaults` library to manage state globally:
- **`Defaults+Extension.swift`**: Declares keys for haptics, menu bar visibility, global rotation sensitivity, direction, and the active controller list.
- **`Defaults+Structures.swift`**: Houses configurations like `Sensitivity` (maps dial steps into degree intervals for continuous vs. stepping rotations) and `Direction` (customizes physical rotation polarity).

---

## How to Build and Run

To compile and launch Dial locally:

### 1. Build HIDAPI Static Library
Dial links against `hidapi` statically. A build script is provided to compile a universal static binary (`x86_64` and `arm64`) from the submodule source:
```bash
./build_hidapi.sh
```

### 2. Compile in Xcode
1. Open `Dial.xcodeproj` in Xcode.
2. Select the `Dial` target and choose your macOS destination.
3. Build and Run (`Cmd + R`).

### Security & Permissions Note
To synthesize global mouse and keyboard events, Dial requires **Accessibility Permissions**.
- Upon the first launch, Dial will prompt you to grant Accessibility access in **System Settings > Privacy & Security > Accessibility**.
- Because Dial interacts globally with user input, the App Sandbox is disabled (`com.apple.security.app-sandbox` is set to `false` in `Dial.entitlements`).

---

## Dependencies

Dial stands on the shoulders of these incredible open-source projects:
- [libusb/hidapi](https://github.com/libusb/hidapi) - Low-level HID device communications.
- [sindresorhus/Defaults](https://github.com/sindresorhus/Defaults) - Elegant user defaults state management.
- [sindresorhus/LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin) - Seamless macOS auto-launch integration.
- [orchetect/MenuBarExtraAccess](https://github.com/orchetect/MenuBarExtraAccess) - Advanced SwiftUI MenuBarExtra utility.
- [orchetect/SettingsAccess](https://github.com/orchetect/SettingsAccess) - Direct access to App Settings.
- [SFSafeSymbols/SFSafeSymbols](https://github.com/SFSafeSymbols/SFSafeSymbols) - Safe compile-time SF Symbols referencing.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.