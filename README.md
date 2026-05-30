# NXBoot

A modern macOS application for provisioning Tegra X1 powered devices with early boot code. Inject payloads like Hekate bootloader or Lakka Linux into Nintendo Switch devices in RCM mode.

**Version**: 2.2.0  
**Repository**: https://github.com/steveshi0/nxboot

**Disclaimer:** Early boot code has full access to the device it runs on and can damage it. No boot code is shipped with this application. Responsibility for consequences of using this application and executing boot code remains with the user.

## Features

* **Native macOS App**: Modern SwiftUI interface designed for macOS 14+
* **Real-time Monitoring**: Automatically detects Nintendo Switch in RCM mode via USB
* **Payload Management**: Store, manage, and easily switch between multiple payloads
* **Hekate Integration**: Deep integration with Hekate, allowing dynamic configuration of boot targets and UMS modes directly from the GUI
* **Auto-Injection**: Enable "Auto-Boot" to immediately inject a pre-selected payload upon device connection
* **Live Logs**: View both application system logs and real-time serial (EP1) logs from your Switch
* **CLI Power**: Embedded `nxboot` command-line tool with built-in system-wide installer (`/usr/local/bin/nxboot`)
* **Multilingual Support**: Fully localized in English and Simplified Chinese
* **Configurable Settings**: Adjust USB timeouts and log limits to suit your needs (v2.2.0+)

## What's New in 2.2.0

### Code Quality Improvements
- **Unified Constants Management**: All hardcoded values centralized in `Constants.swift`
- **Dynamic Configuration**: Bundle identifiers and paths now use dynamic resolution
- **Version Management**: Version numbers read dynamically from bundle info
- **Fixed Settings**: Implemented "Clear Payload Cache" and fixed payload selection inconsistencies

### New User-Configurable Settings
- **USB Read Timeout**: Adjust timeout (100-10,000 ms) for different device response speeds
- **System Log Limit**: Configure system log entries (100-10,000) to balance memory and history
- **Device Log Limit**: Configure device output log entries (100-10,000) for debugging needs
- **Reset to Defaults**: One-click restoration of all settings to default values

See [CHANGELOG.md](CHANGELOG.md) for complete details.

## Prerequisites

* A Mac running macOS 14.0 or later
* A USB-C to USB-C or USB-A to USB-C cable compatible with data transfer
* A Nintendo Switch capable of entering RCM mode (Tegra X1 based)

## Installation

### From Source

1. Clone the repository:
   ```bash
   git clone https://github.com/steveshi0/nxboot.git
   cd nxboot
   ```

2. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```

3. Build the application:
   ```bash
   ./build.sh
   ```
   Or open `NXBoot.xcodeproj` in Xcode and build manually.

### CLI Tool Installation

Use the **Install CLI Tool** button in the app's "About" screen to install the `nxboot` command-line tool system-wide to `/usr/local/bin/nxboot`.

## Usage

### GUI Application

1. Launch NXBoot.app
2. Import your payload files (e.g., Hekate) via the "Payloads" tab
3. Select a default payload in Settings or Dashboard
4. Put your Nintendo Switch into RCM mode
5. Connect via USB - the payload will auto-inject if Auto-Boot is enabled

### Command-Line Tool

```bash
# Basic usage
nxboot payload.bin

# Hekate with specific boot target
nxboot --hekate id BOOT_ID hekate.bin

# Hekate UMS mode
nxboot --hekate ums sd hekate.bin

# Daemon mode (keep running)
nxboot -d payload.bin

# Read device output
nxboot -k payload.bin
```

Run `nxboot --help` for complete usage information.

## Components

* **NXBoot (App)**: The primary native macOS SwiftUI application
* **NXBootCmd**: High-performance C-based command-line tool for payload injection
* **NXBootKit**: The core Objective-C framework providing USB monitoring and injection logic

## Configuration

Settings can be adjusted in the Settings tab:

- **Default Payload**: Choose which payload to inject automatically
- **Auto-Boot**: Enable/disable automatic injection on device connection
- **USB Read Timeout**: Adjust for slower/faster devices (default: 1000ms)
- **Log Limits**: Control memory usage by adjusting log entry limits
- **Notifications**: Toggle device connection notifications

See [ENHANCEMENT_GUIDE.md](ENHANCEMENT_GUIDE.md) for detailed configuration options.

## Documentation

- [CHANGELOG.md](CHANGELOG.md) - Version history and changes
- [REFACTORING_SUMMARY.md](REFACTORING_SUMMARY.md) - Code refactoring details
- [ENHANCEMENT_GUIDE.md](ENHANCEMENT_GUIDE.md) - Configuration and usage guide
- [CLAUDE.md](CLAUDE.md) - Development guidelines for AI assistants

## License
 
Copyright (C) 2018-2024 Oliver Kuckertz  
Copyright (C) 2026 SteveShi
 
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

## Acknowledgments

This project is a fork and continuation of the original [NXBoot by Oliver Kuckertz (@mologie)](https://github.com/mologie/nxboot). Special thanks to Oliver for creating the original implementation and making it open source.

### Original Work

The original NXBoot was created by Oliver Kuckertz and provided the foundation for this project, including:
- The core Fusée Gelée exploit implementation
- USB device enumeration and communication via IOKit
- Hekate payload customization logic
- The original macOS application architecture

### Exploit Discovery

CVE-2018-6242 (Fusée Gelée) was discovered by:
- **Kate Temkin** (@ktemkin) - Fusée Gelée implementation
- **fail0verflow** (@fail0verflow) - ShofEL2 implementation

### Community

Special thanks to the Nintendo Switch homebrew community for their groundbreaking work and continued support of the homebrew ecosystem.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Support

For issues, questions, or feature requests, please use the [GitHub Issues](https://github.com/steveshi0/nxboot/issues) page.

