import Foundation
import SwiftUI

/// Общее состояние приложения: входящие deep links и статус файла сопряжения.
@MainActor
final class AppState: ObservableObject {
    /// Ссылка на IPA, пришедшая по `nortinstall://install` — её подхватывает InstallView.
    @Published var pendingInstallURL: URL?

    @Published var pairingFileImported = false

    /// Сертификат подписи (PKCS#12), пришедший по ссылке или импортированный вручную.
    @Published var certificate: ImportedCertificate?

    /// Короткое уведомление о результатах разбора deep link.
    @Published var schemeNotice: String?

    init() {
        // Заглушка хранения: пароль к p12 в проде должен жить в Keychain,
        // а не в UserDefaults. См. README, шаг 2 roadmap.
        if let raw = UserDefaults.standard.data(forKey: "importedCertificate"),
           let imported = try? JSONDecoder().decode(ImportedCertificate.self, from: raw) {
            certificate = imported
        }

        if let support = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) {
            let pairingFile = support.appendingPathComponent("pairing.mobiledevicepairing")
            pairingFileImported = FileManager.default.fileExists(atPath: pairingFile.path)
        }
    }

    func handle(url: URL) {
        guard let action = URLScheme.parse(url) else {
            schemeNotice = "Ссылка не распознана: \(url.absoluteString)"
            return
        }

        switch action {
        case .installIPA(let ipaURL):
            pendingInstallURL = ipaURL
            schemeNotice = nil
        case .pairingFile:
            pairingFileImported = true
            schemeNotice = "Файл сопряжения получен по ссылке"
        case .certificate(let data, let password):
            importCertificate(data: data, password: password, fileName: "из ссылки")
        }
    }

    func importCertificate(data: Data, password: String, fileName: String) {
        let imported = ImportedCertificate(
            fileName: fileName,
            base64Data: data.base64EncodedString(),
            password: password
        )

        certificate = imported
        if let raw = try? JSONEncoder().encode(imported) {
            UserDefaults.standard.set(raw, forKey: "importedCertificate")
        }
        schemeNotice = "Сертификат сохранён"
    }
}

/// Сертификат подписи: пока хранится как base64, пароль — рядом (заглушка).
struct ImportedCertificate: Codable, Equatable {
    let fileName: String
    let base64Data: String
    let password: String
}
