import SwiftUI

struct HekateView: View {
    @Environment(PayloadManager.self) private var payloadManager
    @Environment(HekateManager.self) private var hekateManager
    @AppStorage("defaultPayloadID") private var defaultPayloadID: String = ""
    
    private var selectedPayload: NXPayload? {
        payloadManager.payloads.first { $0.id.uuidString == defaultPayloadID } ?? payloadManager.payloads.first
    }
    
    private var isHekate: Bool {
        guard let payload = selectedPayload,
              let data = try? Data(contentsOf: payload.path) else { return false }
        return hekateManager.isHekate(data)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isHekate {
                List {
                    Section {
                        HStack {
                            Text(String(localized: "Boot Target"))
                            Spacer()
                            Picker("", selection: Bindable(hekateManager).bootTarget) {
                                ForEach(HekateManager.BootTarget.allCases) { target in
                                    Text(target.localizedName).tag(target)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 150)
                        }
                        
                        if hekateManager.bootTarget == .id {
                            HStack {
                                Text(String(localized: "Entry ID"))
                                Spacer()
                                TextField(String(localized: "e.g. atmospheric"), text: Bindable(hekateManager).bootID)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 150)
                            }
                        }
                        
                        if hekateManager.bootTarget == .index {
                            HStack {
                                Text(String(localized: "Entry Index"))
                                Spacer()
                                Stepper(value: Bindable(hekateManager).bootIndex, in: 1...255) {
                                    Text("\(hekateManager.bootIndex)")
                                }
                                .labelsHidden()
                                .frame(width: 150)
                            }
                        }
                        
                        if hekateManager.bootTarget == .ums {
                            HStack {
                                Text(String(localized: "UMS Target"))
                                Spacer()
                                Picker("", selection: Bindable(hekateManager).umsTarget) {
                                    ForEach(HekateManager.UMSTarget.allCases) { target in
                                        Text(target.localizedName).tag(target)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 150)
                            }
                        }
                    }
                    
                    Section {
                        Toggle(String(localized: "Show Launch Log"), isOn: Bindable(hekateManager).showLaunchLog)
                    }
                }
                .listStyle(.inset)
            } else {
                ContentUnavailableView {
                    Label(String(localized: "Hekate Not Supported"), systemImage: "exclamationmark.triangle")
                } description: {
                    Text(String(localized: "Choose Hekate payload in Payloads tab to configure options."))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(String(localized: "Hekate Options"))
    }
}
