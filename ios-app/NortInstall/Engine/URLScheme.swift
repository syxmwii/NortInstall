import Foundation

enum URLSchemeAction {
    /// `nortinstall://install?url=<percent-encoded https ссылка на .ipa>`
    case installIPA(URL)
    /// `nortinstall://pairingFile?data=<base64>`
    case pairingFile(Data)
    /// `nortinstall://certificate?data=<base64 PKCS#12>&password=<пароль>`
    case certificate(data: Data, password: String)
}

/// Разбор ссылок `nortinstall://`.
enum URLScheme {
    static let scheme = "nortinstall"

    static func parse(_ url: URL) -> URLSchemeAction? {
        guard url.scheme?.lowercased() == scheme, let action = url.host() else { return nil }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func param(_ name: String) -> String? {
            items.first { $0.name == name }?.value
        }

        switch action {
        case "install":
            guard let raw = param("url"),
                  let ipaURL = URL(string: raw),
                  ipaURL.scheme == "https"
            else { return nil }
            return .installIPA(ipaURL)

        case "pairingFile":
            guard let raw = param("data"), let data = Data(base64Encoded: raw) else { return nil }
            return .pairingFile(data)

        case "certificate":
            guard let raw = param("data"), let data = Data(base64Encoded: raw) else { return nil }
            return .certificate(data: data, password: param("password") ?? "")

        default:
            return nil
        }
    }
}
