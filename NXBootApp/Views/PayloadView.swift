import SwiftUI

struct PayloadView: View {
    @Environment(PayloadManager.self) private var payloadManager
    @State private var selectedPayloadID: UUID?
    @State private var isImporting: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Table(payloadManager.payloads, selection: $selectedPayloadID) {
                TableColumn(String(localized: "Name"), value: \.name)
                TableColumn(String(localized: "Size"), value: \.sizeString)
                    .width(ideal: 80, max: 100)
                TableColumn(String(localized: "Date Added")) { payload in
                    Text(payload.dateAdded, style: .date)
                        .foregroundColor(.secondary)
                }
                .width(ideal: 120, max: 150)
            }
            .tableStyle(.inset)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: {
                    if let id = selectedPayloadID,
                       let nxPayload = payloadManager.payloads.first(where: { $0.id == id }) {
                        payloadManager.deletePayload(nxPayload)
                        selectedPayloadID = nil
                    }
                }) {
                    Label(String(localized: "Delete"), systemImage: "trash")
                }
                .disabled(selectedPayloadID == nil)
                .help(String(localized: "Delete"))
                
                Button(action: { isImporting = true }) {
                    Label(String(localized: "Add Payload"), systemImage: "plus")
                }
                .help(String(localized: "Add Payload"))
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    payloadManager.importPayload(from: url)
                }
            case .failure(let error):
                Logger.shared.addLog(String(localized: "Import failed: \(error.localizedDescription)"), type: .system)
            }
        }
        .navigationTitle(String(localized: "Payloads"))
    }
}
