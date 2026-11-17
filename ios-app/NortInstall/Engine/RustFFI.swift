import Foundation
import NortInstallFFI

/// Мост к rust-core (см. rust-core/src/lib.rs).
enum RustFFI {
    /// Читает Info.plist из IPA через `ni_ipa_info`.
    static func ipaInfo(at url: URL) throws -> IPAInfo {
        let pointer = url.path.withCString(ni_ipa_info)
        defer { ni_free_string(pointer) }

        guard let pointer, let raw = String(validatingUTF8: pointer) else {
            throw AppError.invalidIPA("rust-core вернул пустой ответ")
        }

        guard let data = raw.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(IPAInfo.self, from: data)
        else {
            // rust-core вернул {"error": "..."} — показываем его текст
            throw AppError.invalidIPA(raw)
        }
        return decoded
    }
}
