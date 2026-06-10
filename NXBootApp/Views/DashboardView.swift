import SwiftUI

struct DashboardView: View {
    @Environment(DeviceManager.self) private var deviceManager
    @Environment(PayloadManager.self) private var payloadManager
    @Environment(HekateManager.self) private var hekateManager
    @AppStorage("defaultPayloadID") private var defaultPayloadID: String = ""
    
    private var selectedPayload: NXPayload? {
        payloadManager.payloads.first { $0.id.uuidString == defaultPayloadID } ?? payloadManager.payloads.first
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Status Card
            VStack {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "nintendo.switch.logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .foregroundColor(deviceManager.isConnected ? .accentColor : .secondary)
                        .shadow(color: .accentColor.opacity(deviceManager.isConnected ? 0.5 : 0), radius: 10)
                }
                
                Text(String(localized: LocalizedStringResource(stringLiteral: deviceManager.statusMessage)))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .padding(.top, 8)
                    .multilineTextAlignment(.center)
                
                if deviceManager.isConnected {
                    Text(String(localized: "Tegra X1 in Recovery Mode (RCM)"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.secondary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
            
            // Core Actions
            VStack(spacing: 20) {
                Button(action: {
                    guard let payload = selectedPayload else {
                        Logger.shared.addLog(String(localized: "No payload selected"), type: .system)
                        return
                    }
                    guard let relocatorURL = Bundle.main.url(forResource: "intermezzo", withExtension: "bin") else {
                        Logger.shared.addLog(String(localized: "intermezzo.bin not found in bundle resources"), type: .system)
                        return
                    }
                    guard let relocatorData = try? Data(contentsOf: relocatorURL) else {
                        Logger.shared.addLog(String(localized: "Failed to load intermezzo.bin"), type: .system)
                        return
                    }
                    guard let payloadData = try? Data(contentsOf: payload.path) else {
                        Logger.shared.addLog(String(localized: "Failed to read payload file"), type: .system)
                        return
                    }
                    
                    let finalPayloadData = hekateManager.customize(payloadData: payloadData)
                    deviceManager.inject(payloadData: finalPayloadData, relocatorData: relocatorData)
                }) {
                    HStack {
                        Image(systemName: "bolt.fill")
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "Inject Payload"))
                                .font(.headline)
                            if let payload = selectedPayload {
                                Text(payload.name)
                                    .font(.caption2)
                                    .opacity(0.8)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 60)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!deviceManager.isConnected || selectedPayload == nil)
                
                // Payload Selection & Auto-Boot
                VStack(spacing: 16) {
                    HStack {
                        Label(String(localized: "Select Payload"), systemImage: "briefcase")
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("", selection: $defaultPayloadID) {
                            ForEach(payloadManager.payloads) { payload in
                                Text(payload.name).tag(payload.id.uuidString)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 180)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label(String(localized: "Enable Auto-Boot"), systemImage: "bolt.badge.a")
                                .foregroundColor(.secondary)
                            Spacer()
                            Toggle("", isOn: Bindable(deviceManager).isAutoBootEnabled)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                        
                        Text(String(localized: "Auto-Boot Description"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(16)
            }
            .frame(maxWidth: 400) // Keep the UI focused and aligned in the center
            
            Spacer()
        }
        .padding(32)
        .navigationTitle(String(localized: "Dashboard"))
        .onAppear {
            setupAutoInject()
        }
    }
    
    private func setupAutoInject() {
        deviceManager.onAutoInject = {
            guard let payload = selectedPayload else {
                Logger.shared.addLog(String(localized: "No payload selected"), type: .system)
                return (nil, nil)
            }
            guard let relocatorURL = Bundle.main.url(forResource: "intermezzo", withExtension: "bin") else {
                Logger.shared.addLog(String(localized: "intermezzo.bin not found in bundle resources"), type: .system)
                return (nil, nil)
            }
            guard let relocatorData = try? Data(contentsOf: relocatorURL) else {
                Logger.shared.addLog(String(localized: "Failed to load intermezzo.bin"), type: .system)
                return (nil, nil)
            }
            guard let payloadData = try? Data(contentsOf: payload.path) else {
                Logger.shared.addLog(String(localized: "Failed to read payload file"), type: .system)
                return (nil, nil)
            }
            
            let finalPayloadData = hekateManager.customize(payloadData: payloadData)
            return (finalPayloadData, relocatorData)
        }
    }
}
