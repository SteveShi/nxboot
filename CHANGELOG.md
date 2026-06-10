# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.1] - 2026-06-10

<div lang="zh-Hans">

### 修复
- **修复 Switch 注入失效问题**：修复了点击“注入 Payload”按钮及自动注入没有反应的 Bug，补全了应用包中缺失的 `intermezzo.bin` 资源。
- **命令行工具修复**：为 `nxboot` 命令行工具嵌入了默认 relocator (`intermezzo.bin`)。
- **Swift 6 严格并发适配**：解决了严格并发隔离模式下关于 `NXUSBDeviceInterface **` 指针数据竞争的编译报错。
- **消除硬编码字符串**：移除了所有硬编码字符串并补全了完整的英文与中文本地化。

</div>

---

<div lang="en">

### Fixed
- **Fixed Switch Injection Failure**: Resolved the bug where clicking "Inject Payload" or auto-booting had no effect, restoring the missing `intermezzo.bin` resource in the application bundle.
- **CLI Tool Fix**: Embedded the default relocator (`intermezzo.bin`) into the `nxboot` command-line tool.
- **Swift 6 Strict Concurrency**: Fixed compilation errors concerning strict region isolation of non-Sendable `NXUSBDeviceInterface **` pointers.
- **Localization Polish**: Removed all hardcoded strings and completed full English and Simplified Chinese localizations.

</div>

## [2.2.0] - 2026-05-31

### Added
- **User-Configurable USB Timeout**: Adjust USB read timeout (100-10,000 ms) to accommodate different device response speeds
- **User-Configurable Log Limits**: Configure system log entries (100-10,000) and device log entries (100-10,000) to balance memory usage and history
- **Reset to Defaults**: One-click button to restore all settings to default values with confirmation dialog
- **Constants Management**: New `Constants.swift` file centralizing all configuration constants (USB IDs, paths, timeouts, URLs, copyright)
- **Enhanced Settings UI**: Reorganized settings with new sections for USB Communication and Logging, including input validation and help text
- **Comprehensive Documentation**: Added `REFACTORING_SUMMARY.md` and `ENHANCEMENT_GUIDE.md` with detailed technical documentation

### Changed
- **Bundle Identifier**: Updated from `io.mologie.nxboot.*` to `io.steveshi.nxboot.*`
- **Repository URLs**: Updated all references from `mologie/nxboot` to `steveshi0/nxboot`
- **Copyright Information**: Added "© 2026 SteveShi" to all copyright notices while preserving original author attribution
- **Version Management**: AboutView now reads version dynamically from Bundle instead of hardcoded string
- **Payload Directory**: PayloadManager now uses dynamic bundle identifier for Application Support path
- **CLI Installation Path**: Extracted to constant and reused across all references
- **Settings View**: Complete rewrite with proper payload selection using UUID instead of hardcoded strings
- **Log Management**: Logger now uses configurable limits from UserDefaults instead of hardcoded values
- **USB Communication**: DeviceManager now uses configurable timeout from UserDefaults

### Fixed
- **Settings Payload Selection**: Fixed inconsistency between SettingsView (hardcoded "Hekate"/"Fusée") and DashboardView (UUID-based selection)
- **Clear Payload Cache**: Implemented previously non-functional button with confirmation dialog
- **Hardcoded Values**: Removed 23 instances of hardcoded values including:
  - 8 USB VID/PID references
  - 4 path references
  - 3 version number references
  - 5 URL references
  - 2 logic inconsistencies
  - 1 empty function implementation

### Technical Improvements
- **Code Architecture**: Centralized constant management improves maintainability
- **Dynamic Configuration**: Settings now persist in UserDefaults and apply in real-time
- **Input Validation**: All numeric settings have range validation with automatic clamping
- **Memory Management**: Configurable log limits allow users to optimize memory usage
- **Flexibility**: USB timeout configuration enables adaptation to different device characteristics

### Documentation
- Updated README.md with acknowledgment to original author Oliver Kuckertz
- Added "What's New in 2.2.0" section highlighting major improvements
- Added configuration documentation and usage examples
- Created comprehensive refactoring and enhancement guides

## [2.1.0] - 2026-03-20

### Added
- **Modern SwiftUI UI**: Complete rewrite of the macOS application with a premium, native look and feel
- **Hekate Logic**: Deep integration with Hekate, supporting dynamic boot targets (Menu, UMS, ID, Index) and UMS mount points
- **Serial Logs (EP1)**: Support for real-time asynchronous serial log monitoring from Switch USB EP1
- **CLI Installer**: Built-in system installer for the `nxboot` command-line tool (`/usr/local/bin/nxboot`)
- **Native About Menu**: Custom menu bar "About" integration presenting the feature-rich AboutView
- **CI/CD Pipeline**: GitHub Actions workflow for automated DMG and ZIP releases on version tags

### Changed
- **Branding**: Unified application name to **NXBoot**
- **Refinement**: Polished UI alignment across all views (Dashboard, Payloads, Hekate, Logs)
- **Security**: Secure CLI installation path using AppleScript for authenticated privilege escalation
- **Compliance**: Fully updated to **GPLv3** license and updated project attribution

### Removed
- **Legacy Components**: Stripped out non-functional AppCenter SDK and legacy iOS-specific code to streamline the macOS experience

---

## Acknowledgments

This project is a continuation of the original NXBoot by Oliver Kuckertz (@mologie).
Version 2.2.0 represents a significant refactoring and enhancement while maintaining
the core functionality and spirit of the original project.

