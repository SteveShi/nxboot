---
id: native-iokit-usb-stack
title: Use native IOKit for USB communication
category: decision
status: active
created: "2026-08-21T06:38:38"
updated: "2026-08-21T06:38:38"
---

<!-- compiled_truth -->
NXBoot interacts directly with macOS IOKit USB pipes, avoiding third-party dynamic libraries like libusb.


## Timeline

- time: 2026-08-21T06:38:38
  kind: decision
  summary: "Created this page: Use native IOKit for USB communication"
  source: git log
  affects: [native-iokit-usb-stack]

- time: 2026-08-21T06:38:38
  kind: decision
  summary: Implemented native IOKit USB communication.
  source: git log
  affects: [native-iokit-usb-stack]
