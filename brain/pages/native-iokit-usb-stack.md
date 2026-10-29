---
id: native-iokit-usb-stack
title: Use native IOKit for USB communication
category: decision
status: active
created: "2026-08-21T06:38:38"
updated: "2026-10-29T18:21:25"
---

<!-- compiled_truth -->
NXBoot interacts directly with macOS IOKit USB pipes, avoiding third-party dynamic libraries like libusb. Device interface lifecycle is managed via COM reference counting (AddRef/Release) to guarantee memory safety during asynchronous background serial reading across device disconnects.


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

- time: 2026-10-29T18:21:19
  kind: note
  summary: "Fixed EXC_BAD_ACCESS in serial reading: NXExecAcquireDeviceInterface retains device interface via AddRef, and NXExecReleaseDeviceInterface safely closes and releases references with NULL guards."
  affects: [native-iokit-usb-stack]

- time: 2026-10-29T18:21:25
  kind: decision
  summary: Document COM reference lifecycle management for IOKit interfaces
  source: brain update-truth
  affects: [native-iokit-usb-stack]
