import Foundation

/// Клиент anisette-сервера, совместимого с anisette-v3-server.
///
/// Сервер возвращает JSON-мапу заголовков вида
/// `{"X-Apple-I-MD": "…", "X-Apple-I-MD-M": "…", "X-Mme-Device-Id": "…"}`.
/// Свой сервер поднимается из https://github.com/SideStore/anisette-v3-server —
/// чужому серверу доверять нельзя, он видит поток аутентификации.
enum AnisetteClient {
    static func fetch(from serverURL: URL) async throws -> [String: String] {
        guard serverURL.scheme == "https" else {
            throw AppError.invalidInput("anisette-сервер должен быть https")
        }

        let (data, response) = try await URLSession.shared.data(from: serverURL)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AppError.downloadFailed("anisette-сервер ответил \(response)")
        }

        let headers = try JSONDecoder().decode([String: String].self, from: data)
        guard !headers.isEmpty else {
            throw AppError.invalidInput("anisette-сервер вернул пустой ответ")
        }
        return headers
    }
}
