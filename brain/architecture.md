---
slug: architecture
title: System architecture
role: system architecture
updated: "2026-08-21T06:38:38"
---

# System architecture

```mermaid
graph TD
    App[NXBoot App] --> Views[SwiftUI Control Panel & Log Window]
    Views --> DM[DeviceManager IOKit Listener]
    Views --> Injector[Tegra X1 RCM Injector]
    DM --> IOKit[macOS IOKit USB Subsystem]
    Injector --> IOKit
```
