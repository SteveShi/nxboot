import SwiftUI

struct SettingsView: View {
    @Environment(PayloadManager.self) private var payloadManager
    @Environment(DeviceManager.self) private var deviceManager
    @AppStorage("defaultPayloadID") private var defaultPayloadID: String = ""
    @AppStorage("showNotifications") private var showNotifications = true
    @AppStorage("usbReadTimeoutMS") private var usbReadTimeoutMS: Int = Int(AppConstants.defaultUSBReadTimeoutMS)
    @AppStorage("maxSystemLogEntries") private var maxSystemLogEntries: Int = AppConstants.defaultMaxSystemLogEntries
    @AppStorage("maxDeviceLogEntries") private var maxDeviceLogEntries: Int = AppConstants.defaultMaxDeviceLogEntries
    @State private var showingClearConfirmation = false
    @State private var showingResetConfirmation = false

    var body: some View {
        Form {
            Section("General") {
                HStack {
                    Text("Default Payload")
                    Spacer()
                    Picker("", selection: $defaultPayloadID) {
                        Text("None").tag("")
                        ForEach(payloadManager.payloads) { payload in
                            Text(payload.name).tag(payload.id.uuidString)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 200)
                }
            }

            Section(header: Text("Notifications")) {
                Toggle("Show Device Notifications", isOn: $showNotifications)
            }

            Section(header: Text("USB Communication")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Read Timeout")
                        Spacer()
                        TextField("", value: $usbReadTimeoutMS, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                        Text("ms")
                            .foregroundColor(.secondary)
                    }
                    Text("Range: \(AppConstants.minUSBReadTimeoutMS)-\(AppConstants.maxUSBReadTimeoutMS) ms. Lower values may cause read errors.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Logging")) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("System Log Limit")
                            Spacer()
                            TextField("", value: $maxSystemLogEntries, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                                .multilineTextAlignment(.trailing)
                            Text("entries")
                                .foregroundColor(.secondary)
                        }
                        Text("Maximum number of system log entries to keep in memory.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Device Log Limit")
                            Spacer()
                            TextField("", value: $maxDeviceLogEntries, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                                .multilineTextAlignment(.trailing)
                            Text("entries")
                                .foregroundColor(.secondary)
                        }
                        Text("Maximum number of device output entries to keep in memory.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Advanced")) {
                VStack(spacing: 8) {
                    Button("Clear Payload Cache") {
                        showingClearConfirmation = true
                    }
                    .foregroundColor(.red)

                    Button("Reset to Defaults") {
                        showingResetConfirmation = true
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 550)
        .alert("Clear Payload Cache", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearPayloadCache()
            }
        } message: {
            Text("This will delete all imported payloads. This action cannot be undone.")
        }
        .alert("Reset to Defaults", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetToDefaults()
            }
        } message: {
            Text("This will reset all settings to their default values.")
        }
        .onChange(of: usbReadTimeoutMS) { _, newValue in
            // Validate and clamp USB timeout
            let clamped = max(Int(AppConstants.minUSBReadTimeoutMS), min(newValue, Int(AppConstants.maxUSBReadTimeoutMS)))
            if clamped != newValue {
                usbReadTimeoutMS = clamped
            }
        }
        .onChange(of: maxSystemLogEntries) { _, newValue in
            // Validate and clamp system log entries
            let clamped = max(AppConstants.minLogEntries, min(newValue, AppConstants.maxLogEntriesLimit))
            if clamped != newValue {
                maxSystemLogEntries = clamped
            }
        }
        .onChange(of: maxDeviceLogEntries) { _, newValue in
            // Validate and clamp device log entries
            let clamped = max(AppConstants.minLogEntries, min(newValue, AppConstants.maxLogEntriesLimit))
            if clamped != newValue {
                maxDeviceLogEntries = clamped
            }
        }
    }

    private func clearPayloadCache() {
        for payload in payloadManager.payloads {
            payloadManager.deletePayload(payload)
        }
        defaultPayloadID = ""
        Logger.shared.addLog("Payload cache cleared", type: .system)
    }

    private func resetToDefaults() {
        usbReadTimeoutMS = Int(AppConstants.defaultUSBReadTimeoutMS)
        maxSystemLogEntries = AppConstants.defaultMaxSystemLogEntries
        maxDeviceLogEntries = AppConstants.defaultMaxDeviceLogEntries
        showNotifications = true
        Logger.shared.addLog("Settings reset to defaults", type: .system)
    }
}
