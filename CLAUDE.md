# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NXBoot is a macOS application for provisioning Tegra X1 devices (Nintendo Switch) with early boot code via USB. It enables injecting payloads like Hekate bootloader into devices in RCM (Recovery Mode).

**Key capabilities:**
- Real-time USB monitoring for Nintendo Switch in RCM mode (VID: 0x0955, PID: 0x7321)
- Payload injection using the Fusée Gelée exploit (CVE-2018-6242)
- Deep Hekate bootloader integration with dynamic configuration
- Serial output reading from USB EP1 for device logs
- Auto-injection on device connection
- Bilingual support (English and Simplified Chinese)

## Architecture

### Three-Layer Structure

1. **NXBootKit** (Objective-C framework)
   - Core USB device enumeration and monitoring (`NXUSBDeviceEnumerator`)
   - Low-level payload injection via IOKit (`NXExec.m`)
   - Hekate payload customization (`NXHekateCustomizer`)
   - Defines the public API used by both the app and CLI tool

2. **NXBootApp** (SwiftUI macOS app)
   - Modern SwiftUI interface using Swift Observation framework
   - Manager pattern: `DeviceManager`, `PayloadManager`, `HekateManager`, `Logger`, `CLIInstaller`
   - Bridges to NXBootKit via `NXBoot-Bridging-Header.h`
   - Embeds the CLI tool as a resource

3. **NXBootCmd** (C command-line tool)
   - Standalone `nxboot` CLI for scripting and automation
   - Links directly against NXBootKit
   - Can be installed system-wide to `/usr/local/bin/nxboot`

### Critical Technical Details

**USB Communication Flow:**
1. `NXUSBDeviceEnumerator` monitors for Tegra X1 devices via IOKit notifications
2. On connection, `DeviceManager` receives delegate callbacks
3. `NXExec()` acquires USB device interface and performs the exploit:
   - Sends `intermezzo.bin` relocator (92 bytes) to prepare the device
   - Sends the actual payload (up to ~126KB max for Fusée)
   - Uses specific USB control transfers and bulk writes
4. After injection, reads serial output from USB EP1 in background task

**Hekate Integration:**
- Hekate payloads contain a magic signature that `NXHekateCustomizer` detects
- Configuration is patched directly into the payload binary before injection
- Supports boot targets (menu/ID/index/UMS), storage targets, and launch log flags
- This allows GUI-driven configuration without modifying Hekate's INI files

**Localization:**
- Uses SwiftUI's `String(localized:)` API
- Localizable.strings files in `NXBootApp/Resources/{en,zh-Hans}.lproj/`
- All user-facing strings must be localized

## Build System

The project uses **XcodeGen** to generate the Xcode project from `project.yml`. Never edit `NXBoot.xcodeproj` directly—changes will be overwritten.

### Essential Commands

```bash
# Generate/regenerate Xcode project (required after project.yml changes)
xcodegen generate

# Build everything (app + CLI) for release
./build.sh

# Build just the app
xcodebuild -scheme NXBootApp -configuration Release -destination "platform=macOS"

# Build just the CLI tool
xcodebuild -scheme NXBootCmd -configuration Release -destination "platform=macOS"

# Open in Xcode
open NXBoot.xcodeproj
```

### Build Outputs

- App: `DerivedData/NXBoot/Build/Products/Release/NXBootApp.app`
- CLI: `DerivedData/NXBoot/Build/Products/Release/nxboot`
- Distribution: `dist/macos/` (created by `build.sh`)

### Version Management

Version is defined in `project.yml`:
- `MARKETING_VERSION`: User-facing version (e.g., "2.1.0")
- `CURRENT_PROJECT_VERSION`: Build number
- Both targets (NXBootApp and NXBootCmd) must have matching versions

## Development Patterns

### Swift Observation Framework

The app uses Swift's modern `@Observable` macro (not `@ObservableObject`):
- Manager classes are marked `@Observable`
- No need for `@Published` or manual `objectWillChange`
- Views automatically track dependencies

### USB Device Lifecycle

`DeviceManager` implements `NXUSBDeviceEnumeratorDelegate`:
- `deviceConnected`: Called when Switch enters RCM mode
- `deviceDisconnected`: Called when device is removed or exits RCM
- `deviceError`: Called on USB enumeration errors

Auto-injection logic:
- If `isAutoBootEnabled` is true, injection happens immediately on connection
- Uses callback `onAutoInject` to get payload/relocator data from `PayloadManager`

### Serial Reading Pattern

After payload injection, a detached `Task` reads from USB EP1:
- Runs in background priority to avoid blocking UI
- Uses `NXReadPipeTO()` with 1-second timeout
- Handles expected error codes (timeout: 0xE000404F, disconnect: 0xE0004051)
- Converts UTF-8 data to strings for logging

### Payload Management

Payloads are stored in app's Application Support directory:
- Path: `~/Library/Application Support/io.mologie.nxboot.app/Payloads/`
- Each payload is a `.bin` file with metadata stored separately
- `PayloadManager` handles CRUD operations and default payload selection

## Code Signing

The project is configured for **unsigned builds** by default:
- `CODE_SIGNING_REQUIRED: NO`
- `CODE_SIGN_IDENTITY: ""`
- This allows building without a developer certificate

For distribution, you may need to:
1. Enable code signing in `project.yml`
2. Add entitlements (already present: `NXBootCmd/nxboot.entitlements`)
3. Notarize using `notarize_cmdline.sh` (requires Apple Developer account)

## Dependencies

- **XcodeGen**: Project generation (`brew install xcodegen`)
- **IOKit**: USB device communication (system framework)
- **intermezzo.bin**: Fusée Gelée relocator (92-byte ARM payload in `Shared/`)

The `Brewfile` and `Gemfile` are for the original developer's environment setup. Core dependencies are minimal.

## CI/CD

GitHub Actions workflow (`.github/workflows/release.yml`):
- Triggers on version tags (`v*`) or manual dispatch
- Uses `latest-stable` Xcode via custom setup action
- Builds unsigned app, creates DMG and ZIP
- Extracts release notes from `CHANGELOG.md`
- Publishes to GitHub Releases

## Important Constraints

1. **Payload size limit**: Fusée Gelée exploit has a maximum payload size (~126KB). This is enforced by `NXMaxFuseePayloadSize` constant.

2. **USB timing**: The exploit requires precise USB timing. Don't add delays or modify the `NXExec.m` control flow without understanding the exploit mechanics.

3. **Thread safety**: USB operations happen on background threads. All UI updates must be dispatched to `@MainActor`.

4. **Hekate version compatibility**: `NXHekateCustomizer` checks for a magic signature. Unsupported Hekate versions will be treated as generic payloads (no customization).

5. **macOS 14+ requirement**: The app uses SwiftUI features only available in macOS 14 (Sonoma) and later.

## When Modifying Code

- **USB/IOKit changes**: Test thoroughly with real hardware. The exploit is timing-sensitive.
- **Localization**: Add strings to both `en.lproj` and `zh-Hans.lproj` Localizable.strings files.
- **Project structure**: Edit `project.yml` and run `xcodegen generate`, not the Xcode project directly.
- **NXBootKit API changes**: Update both the app and CLI tool, as both depend on the framework.
- **Hekate integration**: Verify against current Hekate releases. The binary patching offsets may change between versions.
