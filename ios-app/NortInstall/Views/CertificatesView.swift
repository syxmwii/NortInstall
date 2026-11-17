import SwiftUI
import UniformTypeIdentifiers

struct CertificatesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showImporter = false
    @State private var password = ""

    var body: some View {
        Form {
            if let certificate = appState.certificate {
                Section("Текущий сертификат") {
                    LabeledContent("Источник", value: certificate.fileName)
                    LabeledContent("Размер", value: "\(certificate.base64Data.count / 4 * 3) байт")
                    LabeledContent("Пароль", value: certificate.password.isEmpty ? "—" : "есть")
                }
                Section {
                    Button("Удалить сертификат", role: .destructive) {
                        appState.certificate = nil
                        UserDefaults.standard.removeObject(forKey: "importedCertificate")
                    }
                }
            } else {
                Section {
                    Button("Импортировать .p12") {
                        showImporter = true
                    }
                } footer: {
                    Label(
                        "Сертификат можно получить по ссылке от SideStore " +
                        "(nortinstall://certificate) или импортировать вручную.",
                        systemImage: "checkmark.seal"
                    )
                }

                Section("Пароль от .p12") {
                    SecureField("Пароль", text: $password)
                }
            }

            Section {
                NavigationLink("Справка: DNS и доверие") {
                    HelpView()
                }
            }
        }
        .navigationTitle("Сертификаты")
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [UTType(filenameExtension: "p12") ?? .data]
        ) { result in
            guard case .success(let url) = result else { return }
            do {
                let secured = url.startAccessingSecurityScopedResource()
                defer { if secured { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url)
                appState.importCertificate(
                    data: data,
                    password: password,
                    fileName: url.lastPathComponent
                )
            } catch {
                appState.schemeNotice = error.localizedDescription
            }
        }
    }
}
