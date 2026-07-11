---
sessionId: session-260710-175408-if9z
---

# Requirements

### Overview & Goals

The goal of this task is to re-imagine the Dial app's on-screen display (HUD) as a modern, circular radial selection menu, mimicking the original Microsoft Surface Dial's off-screen capabilities selection menu. This provides an intuitive, highly tactile visual feedback mechanism that perfectly aligns with the physical nature of the device.

---

### Scope

#### In Scope
- Replacing the square `HUDContentView` with a circular radial menu.
- Rendering all currently active/activated controllers along the circumference of the circular menu.
- Displaying a visual indicator/highlight that rotates smoothly along the ring to select a controller.
- Keeping the HUD visible continuously while the dial is held down (Agent Mode / selection mode) and initiating the fade-out timer only after release.
- Displaying the HUD under the current mouse cursor if `dialMenuAppearsAtCursor` is enabled.
- Exposing existing unused configuration options (`dialMenuThickness`, `dialMenuAnimation`, `dialMenuAppearsAtCursor`) in the status bar menu under a dedicated "On-Screen Dial Menu" section.
- Conditionally using SwiftUI's native `.glassEffect(in: Circle())` modifier for the HUD background on macOS 26 and macOS 27, falling back to `.ultraThinMaterial` on older macOS versions.

#### Out of Scope
- Modifying low-level USB/Bluetooth HID reports or haptic profiles.
- Implementing on-screen digitizer coordinate tracking (this Mac app targets standard desktop/laptop displays).

# Technical Design

### Current Implementation

Currently, `HUDWindow` is a square `180x180` borderless window positioned near the bottom-middle of the active screen. `HUDContentView` displays a static vertical stack containing the active controller's icon and name, and fades out after 1.5 seconds.
When entering selection mode (Agent Mode) by holding down the physical dial, the HUD is not initially shown; it only displays when the user starts rotating the dial to cycle through controllers, and fades out immediately if they pause, regardless of whether the dial is still physically held.

---

### Key Decisions

- **SwiftUI-Native Radial Layout**: Use a combination of rotation and offset effects to place active controllers along an outer ring. By applying a rotation effect, offset, and counter-rotation, the icons remain upright while perfectly tracing the circumference of the circle.
- **Sliding Highlight Indicator**: Track the selected controller index in `activatedControllerIDs`. A highlight circle behind the selected ring icon will rotate dynamically using `.rotationEffect` and animate using the user-defined `dialMenuAnimation` default setting.
- **Agent Mode Binding via Combine**: Import the `Combine` framework in `HUDWindow.swift` to observe changes in `MainController.instance.$state`. This lets `HUDManager` pin the HUD visible as long as `isAgent == true`, and only start the fade-out timer when the dial is physically released (`isAgent == false`).
- **Cursor Positioning & Customization**: Update `HUDManager.showHUD` to dynamically read `NSEvent.mouseLocation` and center the HUD window under the cursor if `dialMenuAppearsAtCursor` is enabled.
- **Liquid Glass Material on macOS 26/27**: Check `#available(macOS 26.0, *)` to conditionally apply the `.glassEffect(in: Circle())` background for the HUD on macOS 26 and macOS 27. On older macOS versions, fall back to `.ultraThinMaterial` with a circular clip shape.

---

### Proposed Changes

#### `HUDWindow.swift`
- Increase `HUDWindow`'s size to `220x220` to give the circular layout and ring icons ample spacing.
- Redesign `HUDContentView` to render as a circular dial:
  - Outer circle: Subtle stroke track with radius governed by `dialMenuThickness`.
  - Outer icons: Distributed evenly for all active controllers.
  - Active indicator: A circular capsule that slides to the active controller index.
  - Center area: Displays the selected controller's large icon and name.
  - Background: Apply `.glassEffect(in: Circle())` conditionally if `#available(macOS 26.0, *)` is true, otherwise use `.ultraThinMaterial` background clipped to a circular shape.
- Observe `MainController.instance.$state` using Combine's `@Published` publisher in `HUDManager`.
- Pin HUD visibility while in Agent Mode and trigger `scheduleFadeOut()` on release.
- Center the window under `NSEvent.mouseLocation` if `Defaults[.dialMenuAppearsAtCursor]` is `true`.

#### `MenuBarMenuView.swift`
- Declare `@Default` bindings for `.dialMenuThickness`, `.dialMenuAnimation`, and `.dialMenuAppearsAtCursor`.
- Add a new "On-Screen Dial Menu" section in the menu bar template containing:
  - A Toggle for "Show Menu at Cursor Position".
  - A Picker for "Menu Thickness" (Thin, Regular, Thick).
  - A Picker for "Menu Animation" (None, Linear, Smooth, Bouncy, Spring, etc.).

# Testing

### Validation Approach

Since Dial relies on global inputs and haptic feedback, manual testing is the key validation approach for verifying the user experience and visual styling.

---

### Key Scenarios

#### 1. Press and Hold (Selection Mode)
- **Action**: Press and hold the physical Surface Dial.
- **Expected Outcome**: The circular HUD appears immediately (even before rotation) centered on screen, showing the radial menu with all active controllers. It must remain fully visible as long as the dial is held.

#### 2. Rotate to Cycle Controllers
- **Action**: Rotate the dial while keeping it pressed.
- **Expected Outcome**: The active highlight circle must slide smoothly from icon to icon along the circular track. The center icon and text must update instantly to reflect the newly highlighted controller.

#### 3. Release (Selection Confirmation)
- **Action**: Release the physical dial.
- **Expected Outcome**: The selected controller is confirmed, and the HUD must fade out after 1.5 seconds.

#### 4. Cursor Placement Setting
- **Action**: Enable "Show Menu at Cursor Position" from the menu bar. Move the mouse to any corner of the screen and press-and-hold the dial.
- **Expected Outcome**: The circular HUD must spawn exactly centered under the mouse cursor.

#### 5. Thickness and Animation Tweaks
- **Action**: Change the menu thickness and animation parameters in the menu bar.
- **Expected Outcome**: The outer ring radius adjusts immediately to the selected thickness, and the transition animation updates to match the selected profile (e.g. springy or instant).

# Delivery Steps

### ✓ Step 1: Redesign HUDContentView to display a Circular Radial Menu
The HUD is displayed as a circular radial menu with all active controllers distributed around an outer track.

- Update `HUDWindow` dimensions in `HUDWindow.swift` to `220x220` to accommodate circular spacing.
- Implement a circular track layout in `HUDContentView` that calculates and distributes available controllers (`activatedControllerIDs`) evenly along the ring.
- Position a central area within the HUD showing the currently active controller's name and icon.
- Style the HUD background: check `#available(macOS 26.0, *)` to conditionally apply the `.glassEffect(in: Circle())` modifier on macOS 26 and macOS 27, falling back to `.background(.ultraThinMaterial).clipShape(Circle())` on older versions, with a subtle outline stroke.

### ✓ Step 2: Implement Animated Highlight and Agent Mode Persistence
The HUD highlight animates smoothly between controllers and stays visible while the physical dial is held down.

- Add a sliding highlight indicator on the outer ring that tracks the currently selected controller.
- Apply the user's chosen `dialMenuAnimation` and `dialMenuThickness` defaults to customize the transitions and ring size.
- Import `Combine` in `HUDWindow.swift` to observe `MainController.instance.$state`.
- Prevent the HUD from fading out when in Agent Mode (`isAgent == true`), and trigger a delayed fade-out only when the dial is released (`isAgent == false`).

### ✓ Step 3: Expose On-Screen Dial Menu Customization Settings in Menu Bar UI
The user can toggle HUD position under the cursor and customize menu thickness and animation styles from the status bar menu.

- Add `@Default` property wrappers for `dialMenuAppearsAtCursor`, `dialMenuThickness`, and `dialMenuAnimation` in `MenuBarMenuView.swift`.
- Update window positioning logic in `HUDManager.showHUD` to center the HUD under the mouse cursor (`NSEvent.mouseLocation`) when `dialMenuAppearsAtCursor` is enabled.
- Add an "On-Screen Dial Menu" section in `MenuBarMenuView.swift` with options to toggle cursor-placement and select thickness and animation profiles.