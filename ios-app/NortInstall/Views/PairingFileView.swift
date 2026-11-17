import SwiftUI
import UniformTypeIdentifiers

struct PairingFileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showImporter = false
    @State private var importedName: String?

    var body: some View {
        Form {
            Section {
                Button("Импортировать файл сопряжения") {
                    showImporter = true
                }
                if let importedName {
                    Label(importedName, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            } footer: {
                Text(
                    """
                    Файл сопряжения позволяет приложению ставить IPA на ваш iPhone \
                    как «компьютеру».

                    • iOS 27+ — создаётся на устройстве, без ПК.
                    • iOS 17.4–26.x — сделайте его на компьютере (jitterbugpair, \
                    pymobiledevice3, idevice_pair) и импортируйте здесь.
                    """
                )
            }
        }
        .navigationTitle("Файл сопряжения")
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.data]) { result in
            switch result {
            case .success(let url):
                importedName = importPairingFile(url)
                appState.pairingFileImported = (importedName != nil)
            case .failure(let error):
                importedName = nil
                appState.schemeNotice = error.localizedDescription
            }
        }
    }

    /// Копирует выбранный файл в Application Support, чтобы он пережил перезапуск.
    private func importPairingFile(_ source: URL) -> String? {
        do {
            let secured = source.startAccessingSecurityScopedResource()
            defer { if secured { source.stopAccessingSecurityScopedResource() } }

            let support = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let destination = support.appendingPathComponent("pairing.mobiledevicepairing")
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: source, to: destination)
            return source.lastPathComponent
        } catch {
            appState.schemeNotice = error.localizedDescription
            return nil
        }
    }
}
